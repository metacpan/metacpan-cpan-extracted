#!/usr/bin/perl
package Acme::ReturnValue::MakeSite;

use 5.010;
use strict;
use warnings;

# ABSTRACT: generate returnvalues.useperl.at

use Path::Class qw();
use URI::Escape;
use Encode qw(from_to);
use Data::Dumper;
use Acme::ReturnValue;
use Encode;
use Moose;
use JSON;
with qw(MooseX::Getopt);
use MooseX::Types::Path::Class;

has 'now' => (is=>'ro',isa=>'Str',default => sub { scalar localtime});
has 'quiet' => (is=>'ro',isa=>'Bool',default=>0);
has 'data' => (is=>'ro',isa=>'Path::Class::Dir',default=>'returnvalues',coerce=>1);
has 'out' => (is=>'ro',isa=>'Path::Class::Dir',default=>'htdocs',coerce=>1);
has 'json_decoder' => (is=>'ro',lazy_build=>1);
sub _build_json_decoder {
    return JSON->new;
}



sub run {
    my $self = shift;

    my @interesting;

    my %cool_dists;
    my %bad_dists;
    my %cool_rvs;
    #my %authors;

    if (!-d $self->out) {
        $self->out->mkpath || die "cannot make dir ".$self->out;
    }

    my $dir = $self->data;
    while (my $file=$dir->next) {
        next unless $file=~/\/(?<dist>.*)\.json$/;
        my $dist=$+{dist};
        $dist=~s/^\///;

        my $json = $file->slurp(iomode => '<:encoding(UTF-8)');
        my $data = $self->json_decoder->decode($json);
        next if ref($data) eq 'HASH' && $data->{is_boring};
        foreach my $rreport (@$data) {
            my $report = { %$rreport };
            if (exists $report->{value}) {
                $report->{value}=~s/\</&lt;/g;
                $report->{value}=~s/\>/&gt;/g;
                if(length($report->{value})>255) {
                    $report->{value}=substr($report->{value},0,255).'...';
                }
            }
            if ($report->{bad}) {
                my $bad = $report->{bad};
                $bad=~s/\</&lt;/g;
                $bad=~s/\>/&gt;/g;
                if(length($bad)>255) {
                    $bad=substr($bad,0,255).'...';
                }
                $report->{bad}=$bad;
            }

            $report->{package_br} = $report->{package};
            if (length($report->{package_br})>40) {
                my @p=split(/::/,$report->{package_br});
                my @lines;
                my $line = shift(@p);
                foreach my $frag (@p) {
                    $line.='::'.$frag;
                    if (length($line)>40) {
                        push(@lines,$line);
                        $line='';
                    }
                }
                push (@lines,$line) if $line;
                $report->{package_br}=join("<br>&nbsp;&nbsp;&nbsp;",@lines);
            }
            if ($report->{value}) {
                push(@{$cool_dists{$dist}},$report);
                push(@{$cool_rvs{$report->{value}}},$report);
            }
            else {
                push(@{$bad_dists{$report->{PPI}}{$dist}},$report);
            }
        }
    }
    
    my %by_letter; 
    foreach my $dist (sort keys %cool_dists) {
        my $first = uc(substr($dist,0,1));
        push(@{$by_letter{$first}},$dist);
    }
    my $letternav = "<ul class='menu'>";
    foreach my $letter (sort keys %by_letter) {
        $letternav.="<li><a href='cool_$letter.html'>$letter</a></li>";
    }
    $letternav.="</ul>";
    foreach my $letter (sort keys %by_letter) {
        $self->gen_cool_dists(\%cool_dists,$by_letter{$letter},$letter,$letternav); 
    }
   
    $self->gen_cool_values(\%cool_rvs);

    $self->gen_bad_dists(\%bad_dists); 
   
    $self->gen_index;

}


sub gen_cool_dists {
    my ($self, $cool,$dists,$letter,$letternav) = @_;

    my $out = Path::Class::Dir->new($self->out)->file('cool_'.$letter.'.html');

    my $count = keys %$cool;
    my @print;

    push(@print,$self->_html_header);
    push(@print,<<EOCOOLINTRO);
<h3>$count Cool Distributions $letter</h3>
<p class="content">A list of distributions with not-boring return 
values, sorted by name. </p>
EOCOOLINTRO
   
    push(@print,$letternav);

    push(@print,"<table>");
    foreach my $dist (sort @{$dists}) {
        push(@print,$self->_html_cool_dist($dist,$cool->{$dist}));
    }
    
    push(@print,"</table>",$self->_html_footer);

    $out->spew(iomode => '>:encoding(UTF-8)', [map { decode_utf8($_) } @print]);

}


sub gen_cool_values {
    my ($self, $dists) = @_;

    my $out = Path::Class::Dir->new($self->out)->file('values.html');
    my @print;

    push(@print,$self->_html_header);
    push(@print,<<EOBADINTRO);
<h3>Cool Return Values</h3>
<p class="content">
All cool values, sorted by number of occurence in the CPAN.
</p>

<table>
<tr><td>Count</td><td>Return value</td><td>Packages</td></tr>
EOBADINTRO

    my $cnt=1;
    foreach my $rv (
        map { $_->[1] }
        sort { $b->[0] <=> $a->[0] }
        map { [scalar @{$dists->{$_}},$_] } keys %$dists) {
        push(@print,$self->_html_cool_value($rv,$dists->{$rv},'cv_'.$cnt++));
    }

    push(@print,"<table>");
    push(@print,$self->_html_footer);
    $out->spew(iomode => '>:encoding(UTF-8)', [map { decode_utf8($_) } @print]);
}


sub gen_bad_dists {
    my ($self, $dists) = @_;

    my $out = Path::Class::Dir->new($self->out)->file('bad.html');
    my @print;

    push(@print,$self->_html_header);
    push(@print,<<EOBADINTRO);
<h3>Bad Return Values</h3>

<p class="content">A list of distributions that don't return a valid 
return statement. You can consider this distributions buggy. This list 
is further broken down into the type of <a 
href="http://search.cpan.org/dist/PPI">PPI::Statement</a> class they 
return. To view the full bad return value, click on the 
'show'-link.</p>
EOBADINTRO

    my @bad = sort keys %$dists;
    push(@print,"<ul>");
    foreach my $type (@bad) {
        my $count = keys %{$dists->{$type}};
        push(@print,"<li><a href='#$type'>$type ($count dists)</li>");
    }
    push(@print,"</ul>");
    
    foreach my $type (sort keys %$dists) {
        push(@print,"<h3><a name='$type'>$type</a></h3>\n<table width='100%'>");
        foreach my $dist (sort keys %{$dists->{$type}}) {
            push(@print, $self->_html_bad_dist($dist,$dists->{$type}{$dist}));

        }
        push(@print,"</table>");
    }
    
    push(@print,"</table>");
    push(@print,$self->_html_footer);
    $out->spew(iomode => '>:encoding(UTF-8)', [map { decode_utf8($_) } @print]);
}


sub gen_index {
    my $self = shift;
    my $out = Path::Class::Dir->new($self->out)->file('index.html');
    my @print;
    my $version = Acme::ReturnValue->VERSION;

    push(@print,$self->_html_header);
    push(@print,<<EOINDEX);

<p class="content">As you might know, all <a href="http://perl.org">Perl</a> packages are required to end with a true statement, usually '1'. But there are more interesting true values than plain old boring '1'. This site is dedicated to presenting to you those creative, funny, stupid or erroneous return values found on <a href="http://search.cpan.org">CPAN</a>.</p>

<p class="content">This site is created using <a href="http://search.cpan.org/dist/Acme-ReturnValue">Acme::ReturnValue $version</a> by <a href="http://domm.plix.at">Thomas Klausner</a> on irregular intervals (but setting up a cron-job is on the TODO...). There are some <a href="http://domm.plix.at/talks/acme_returnvalue.html">slides of talks</a> available with a tiny bit more background.</p>

<p class="content">At the moment, there are the following reports:
<ul class="content">
<li><a href="values.html">Cool values</a> - all cool values, sorted by number of occurence in the CPAN</li>
<li><a href="cool_A.html">Cool dists</a> - a list of distributions with not-boring return values. There still are some false positves hidden in here, which will hopefully be removed soon.</li>
<li><a href="bad.html">Bad return values</a> - a list of distributions that don't return a valid return statement. You can consider this distributions (or Acme::ReturnValue) buggy.</li>
<li>By author - not implemented yet.
</ul>
</p>

EOINDEX
    push(@print,$self->_html_footer);
    $out->spew(iomode => '>:encoding(UTF-8)', [map { decode_utf8($_) } @print]);

}

sub _html_cool_dist {
    my ($self, $dist,$report) = @_;
    my $html;
    my $count = @$report;

    if ($count>1) {
        $html.="<tr><td colspan=2>".$self->_link_dist($dist)."</td></tr>";
    }

    foreach my $ele (@$report) {
        my $val=$ele->{'value'};

        if ($count>1) {
            $html.="<tr><td class='package'>".$ele->{package_br}."</td>";
        }
        else {
            $html.="<tr><td colspan>".$self->_link_dist($dist)."</td>";
        }
        $html.="<td>".$val."</td>";
        $html.="</tr>\n";
    }
    return $html;
}

sub _html_cool_value {
    my ($self, $value, $report, $id) = @_;
    my $html;
    my $count = @$report;
    $html = qq[<tr><td>$count</td><td>$value</td><td><a href="javascript:void(0)" onclick="] . q[$('#]. $id. q[').toggle()">show</td></td></tr>].
qq[<tr id='$id' style='display:none' ><td></td><td colspan=2>];
    $html .= join("<br>\n",map { $self->_link_search_package($_->{package}) } sort { $a->{package} cmp $b->{package} } @$report);
    $html .= "</td></tr>";
    return $html;
}

sub _html_bad_dist {
    my ($self, $dist,$report) = @_;
    my $html;

    foreach my $ele (@$report) {
        my $val=$ele->{'bad'} || '';
        my $id = $ele->{package};
        $id=~s/::/_/g;
        $html.="<tr><td colspan width='30%'>".$self->_link_dist($dist)."</td>";
        $html.="<td width='69%'>".$ele->{package}."</a></td>".
        q{<td width='1%'><a href="javascript:void(0)" onclick="$('#}.$id.q{').toggle()">}."show</td></tr>
        <tr id='$id' style='display:none' ><td></td><td colspan=2>".$val."</td></tr>";
    }
    return $html;
}

sub _link_dist {
    my ($self, $dist) = @_;
    return "<a href='http://search.cpan.org/dist/$dist'>$dist</a>";
}

sub _link_search_package {
    my ($self, $package) = @_;
    return "<a href='http://search.cpan.org/search?query=$package&mode=module'>$package</a>";
}

sub _html_header {
    my $self = shift;

    return <<"EOHTMLHEAD";
<html>
<head><title>Acme::ReturnValue findings</title>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8">
<script src="jquery-1.3.2.min.js" type="text/javascript"></script>
<link href="acme_returnvalue.css" rel="stylesheet" type="text/css">

</head>

<body>
<h1 id="top">Acme::ReturnValue</h1>

<ul id="menubox" class="menu">
<li><a href="index.html">About</a></li>
<li><a href="values.html">Cool return values</a></li>
<li><a href="cool_A.html">Cool dists</a></li>
<li><a href="bad.html">Bad return values</a></li>
</ul>
</div>
EOHTMLHEAD
}

sub _html_footer {
    my $self = shift;
    my $now = $self->now;
    my $version = Acme::ReturnValue->VERSION;
    return <<"EOHTMLFOOT";
<div class="comments">
    <h3>Comments</h3>
    <div id="disqus_thread"></div>
    <script type="text/javascript">
        var disqus_shortname = 'acmereturnvalues';
        var disqus_identifier='same_comments_everywhere';
        (function() {
            var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
            dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';
            (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
        })();
    </script>
    <noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>

</div>
<div class="footer">
<p>Acme::ReturnValue: <a href="http://search.cpan.org/dist/Acme-ReturnValue">on CPAN</a> | <a href="http://domm.plix.at/talks/acme_returnvalue.html">talks about it</a><br>
Contact: domm  AT cpan.org<br>
Generated: $now<br>
Version: $version<br>
</p>
</div>
</body></html>
EOHTMLFOOT
}

"let's generate another stupid website";

__END__

=pod

=head1 NAME

Acme::ReturnValue::MakeSite - generate returnvalues.useperl.at

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    acme_returnvalue_makesite.pl --data path/to/dir

=head1 DESCRIPTION

Generate a small site based on the findings of L<Acme::ReturnValue>

=head2 METHODS

=head3 run

run from the commandline (via F<acme_returnvalue_makesite.pl>

=head3 gen_cool_dists

Generate the list of cool dists.

=head3 gen_cool_values

Generate the list of cool return values.

=head3 gen_bad_dists

Generate the list of bad dists.

=head3 gen_index

Generate the start page

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
