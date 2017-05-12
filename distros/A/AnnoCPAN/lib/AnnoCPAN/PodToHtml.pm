package AnnoCPAN::PodToHtml;

$VERSION = '0.22';

use strict;
use warnings;

use base 'Pod::Parser';
use AnnoCPAN::Config;

=head1 NAME

AnnoCPAN::PodToHtml - Convert POD to HTML

=head1 SYNOPSIS

    # this is low-level use of Pod::Parser, in AnnoCPAN::DBI

    my $parser = AnnoCPAN::PodToHtml->new;

    my %methods = (
        VERBATIM,  'verbatim',
        TEXTBLOCK, 'textblock',
        COMMAND,   'command',
    );

    sub html {
        my ($self) = @_;
        my $method = $methods{$self->type};
        my @args = $self->content;
        if ($method eq 'command') {
            # split into command and content
            @args = $args[0] =~ /==?(\S+)\s+(.*)/s;
        }
        my $html = $parser->$method(@args);
    }

=head1 DESCRIPTION

This is a subclass of L<Pod::Parser> for converting POD into HTML. It overrides
the C<verbatim>, C<textblock>, C<command>, and C<interior_sequence> methods.

=cut

my $root_uri_rel  = AnnoCPAN::Config->option('root_uri_rel');
my $pre_line_wrap = AnnoCPAN::Config->option('pre_line_wrap');

use constant {
    VERBATIM  => 1,
    TEXTBLOCK => 2,
    COMMAND   => 4,
};

sub verbatim {
    my ($self, $text, $line_num, $pod_para) = @_;
    return '' if $self->{annocpan_begin_depth};
    $text =~ s/(.{$pre_line_wrap})(?=.)/$1\n\0<span class="line_cont"\0>+\0<\/span\0>/mgo;
    for ($text) {
        s/(?<!\0)&/&amp;/g;
        s/(?<!\0)</&lt;/g;
        s/(?<!\0)>/&gt;/g;
        s/\0//g;
    }
    my $ret = "<pre>$text</pre>\n";
    $ret = "<div class=\"content\"><div>$ret</div></div>\n"
        unless $self->{annocpan_simple};
    if ($self->{annocpan_print}) {
        my $out_fh = $self->output_handle();
        print $out_fh $ret;
    }
    $ret;
}

sub textblock {
    my ($self, $text, $line_num, $pod_para) = @_;
    return '' if $self->{annocpan_begin_depth};
    my $out_fh = $self->{_OUTPUT};
    my $p = $self->interpolate($text, $line_num);
    for ($p) {
        s/(?<!\0)&/&amp;/g;
        s/(?<!\0)</&lt;/g;
        s/(?<!\0)>/&gt;/g;
        s/\0//g;
    }
    my $ret = "<p>$p</p>\n";
    $ret = "<div class=\"content\">$ret</div>\n"
        unless $self->{annocpan_simple};
    if ($self->{annocpan_print}) {
        my $out_fh = $self->output_handle();
        print $out_fh $ret;
    }
    $ret;
}

sub command {
    my ($self, $cmd, $text, $line_num, $pod_para)  = @_;
    my $p = $self->interpolate($text, $line_num);
    for ($p) {
        s/(?<!\0)&/&amp;/g;
        s/(?<!\0)</&lt;/g;
        s/(?<!\0)>/&gt;/g;
    }
    $p =~ s/\0//g;
    my $method = "ac_c_$cmd";
    $method = "ac_c_default" unless $self->can($method);
    my $ret = $self->$method($p);
    return '' if $self->{annocpan_begin_depth};
    if ($self->{annocpan_print}) {
        my $out_fh = $self->output_handle();
        print $out_fh $ret;
    }
    $ret;
}


sub interior_sequence { 
    my ($self, $seq_command, $seq_argument) = @_ ;
    #print "interior_sequence($seq_command, $seq_argument)\n";
    my $method = "ac_i_$seq_command";
    $method = "ac_i_default" unless $self->can($method);
    my $ret = $self->$method($seq_argument);
    $ret;
}


# trims surrounding whitespace, replaces interior whitespace by underscores,
# removes HTML tags, and URI-escapes non-word characters
sub filter_anchor {
    my ($s) = @_;
    $s = lc $s;
    for ($s) {
        s/^\s+//; 
        s/\s+$//;
        s/\s+/_/g; 
        s/<.*?>//g;
        s/\0//g;
        s/(\W)/sprintf "%%%02x", ord($1)/eg; 
    }
    $s;
}

#### COMMANDS ####

sub ac_c_default { "<p>$_[1]</p>\n" }
sub ac_c_over { "<ul>\n" }
sub ac_c_back { "</ul>\n" }
sub ac_c_head1 { '<a name="' . filter_anchor($_[1]) . '"></a>' . "<h3>$_[1]</h3>\n" }
sub ac_c_head2 { '<a name="' . filter_anchor($_[1]) . '"></a>' . "<h4>$_[1]</h4>\n" }
sub ac_c_head3 { '<a name="' . filter_anchor($_[1]) . '"></a>' . "<h5>$_[1]</h5>\n" }
sub ac_c_head4 { '<a name="' . filter_anchor($_[1]) . '"></a>' . "<h6>$_[1]</h6>\n" }
sub ac_c_for { "" }
sub ac_c_begin { 
    my ($self) = @_;
    $self->{annocpan_begin_depth}++;
    "";
}
sub ac_c_end { 
    my ($self) = @_;
    $self->{annocpan_begin_depth}-- if $self->{annocpan_begin_depth};
    "";
}
sub ac_c_item { 
    my ($self, $content) = @_;
    if (!(length $content) or $content =~ /^[*+-]\s*$/) {
        return '<li class="star">';
    } else {
        $content =~ s/^\s*[*+-]\s*//;
        return "<li><b>$content</b>\n";
    }
}


#### INTERIOR SEQUENCES ####


sub ac_i_default { "\0<span\0>$_[1]\0</span\0>" }
sub ac_i_I { "\0<i\0>$_[1]\0</i\0>" }
sub ac_i_B { "\0<b\0>$_[1]\0</b\0>" }
sub ac_i_C { "\0<code\0>$_[1]\0</code\0>" }
sub ac_i_F { "\0<span class=\"filename\"\0>$_[1]\0</span\0>" }
sub ac_i_S { "\0<span class=\"nbs\"\0>$_[1]\0</span\0>" }
sub ac_i_Z { "" }
sub ac_i_L { 
    my ($self, $ref) = @_ ;
    no warnings 'uninitialized';
    my ($base, $text, $name, $sect);
    if ($ref =~ m{^(?:https?|ftp)://}i) { # uri
        $base = $text = $ref;
        return qq{\0<a href="$ref"\0>$ref\0</a\0>};
    } elsif ($ref =~ /^"([^\/]*)"$/) {
        $sect = $1;
    } else {
        my $rest;
        ($text, $rest) = $ref =~ /^
            (?:([^|]*) \|)?  # text
            (.*)             # rest
        /x;
        ($name, $sect) = split /(?<!<)\//, $rest, 2;
        #print "($text,$name,$sect)\n";
    }
    $sect =~ s/^"|"$//g;

    if (! length $text and ! length $sect and $name =~ /[\s<>]/) {
        # deprecated-style local link
        $sect = $name;
        $name = '';
    }
    #$text =~ s/^"|"$//g;

    # figure out link text
    if ($sect and $name and ! $text) {
        $text = qq{"$sect" in $name} 
    } else {
        $text = $text || $name || qq{"$sect"};
    }
        
    $base = $name ? "$root_uri_rel/perldoc?" : $base;
    my $loc  = $sect ? "#" . filter_anchor($sect) : '';
    return qq{\0<a href="$base$name$loc"\0>$text\0</a\0>};
}

{
    my %escapes = (
        lt      => "<",
        gt      => '>',
        verbar  => '|',
        sol     => '/',
    );

    sub ac_i_E { 
        my $ret;
        $ret = $escapes{$_[1]}   and return $ret;
        $_[1] =~ /^\d+$/         and return chr($_[1]);
        $_[1];
    }
} 

=head1 SEE ALSO

L<AnnoCPAN::DBI>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1;

