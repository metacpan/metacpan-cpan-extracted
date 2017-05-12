#!/usr/bin/perl
# vim: set ts=4 sw=4 tw=78 et si ft=perl:
#
# rfx2xhtml
#
use 5.010;
use strict;
use warnings;

package RFC2XHTML::FSM;

my $state_table = {
    default => {
        'default'   => [ '', \&_abort ],
        'empty'     => [ '', sub {} ],
        'pagefoot'  => [ '', sub {} ],
        'pagehead'  => [ '', sub {} ],
    },
    abstract => {
        'toc'   => [ 'toc', \&_begin_toc ],
        'empty' => [ '', \&_print_paragraph ],
        'text'  => [ '', \&_collect_text ],
    },
    author  => {
        'empty'         => [ '', \&_print_pre ],
        'fullcopyright' => [ 'body', \&_begin_h2 ],
        'text'          => [ '', \&_collect_text ],
    },
    banner  => {
        'text'  => [ '', \&_collect_text ],
        'empty' => [ 'have_banner', \&_print_pre ],
    },
    body    => {
        'author'        => [ 'author', \&_begin_h2 ],
        'empty'         => [ '', \&_print_paragraph ],
        'footnotes'     => [ '', \&_begin_h2 ],
        'fullcopyright' => [ '', \&_begin_h2 ],
        'head1'         => [ '', \&_begin_h2 ],
        'head2'         => [ '', \&_begin_h3 ],
        'head3'         => [ '', \&_begin_h4 ],
        'head4'         => [ '', \&_begin_h5 ],
        'references'    => [ '', \&_begin_h2 ],
        'security'      => [ '', \&_begin_h2 ],
        'text'          => [ '', \&_collect_text ],
    },
    copynote    => {
        'abstract'  => [ 'abstract', \&_begin_h2 ],
        'empty'     => [ '', \&_print_paragraph ],
        'text'      => [ '', \&_collect_text ],
    },
    have_banner  => {
        'text'  => [ 'title', \&_collect_text ],
    },
    have_title  => {
        'status'    => [ 'status', \&_begin_h2 ],
    },
    start   => {
        'text'  => [ 'banner', \&_collect_text ],
    },
    status  => {
        'copynote'  => [ 'copynote', \&_begin_h2 ],
        'empty'     => [ '', \&_print_paragraph ],
        'text'      => [ '', \&_collect_text ],
    },
    title   => {
        'text'  => [ '', \&_collect_text ],
        'empty' => [ 'have_title', \&_print_title ],
    },
    toc => {
        'head1'     => [ 'body', \&_end_toc_h2 ],
        'text'      => [ '', \&_print_toctext ],
        'tocline'   => [ '', \&_print_tocline ],
    },
};

sub new {
    my ($self,$args) = @_;
    my $type = ref($self) || $self;

    $self = bless {}, $type;
    $self->_init($args);
    return $self;
} # new();

sub event {
    my ($self,$event,@args) = @_;
    my ($action,$next);
    my $sn      = $self->{state};
    my $state   = $state_table->{$sn};
    my $default = $state_table->{default};

    if ($state->{$event}) {
        $next   = $state->{$event}->[0] || $sn;
        $action = $state->{$event}->[1];
    }
    elsif ($default->{$event}) {
        $next   = $default->{$event}->[0] || $sn;
        $action = $default->{$event}->[1] || $sn;
    }
    elsif ($state->{default}) {
        $next   = $state->{default}->[0] || $sn;
        $action = $state->{default}->[1];
    }
    elsif ($default->{default}) {
        $next   = $default->{default}->[0] || $sn;
        $action = $default->{default}->[1];
    }
    else {
        my $line = $args[0] || '';
        die "FSM: can't handle event($event) in state($sn): $line";
    }
    $self->{nextstate} = $next;
    $action->($self,$event,@args);
    $next = $self->{nextstate};
    if ($state_table->{$next}) {
        $self->{state} = $next;
    }
    else {
        my $line = $args[0] || '';
        die "FSM: unknown next state($next)\n"
          . "     after event($event) in state($sn): $line";
    }
} # event()

sub start {
    my ($self,$args) = @_;

    if ($args) {
        $self->_init($args);
    }
    my $xmlns   = $self->{xmlns};
    my $title   = $self->{title};
    my $head = <<"EOHEAD";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="$xmlns">
<head ><title >$title</title>
<link rel="stylesheet" href="rfc.css" type="text/css" />
</head>
<body>
EOHEAD
    print $head;
    $self->{state} = 'start';
} # start()

sub stop {
    my ($self) = @_;
    my $foot    = <<EOFOOT;
</body>
</html>
EOFOOT
    print $foot;
    $self->{state} = 'stop';
} # stop();

sub _abort {
    my ($self,$event,$line,$args) = @_;
    my @args = sort map { "$_($args->{$_})" } keys %$args;
    my $state = $self->{state};
    my $text = $args->{text} ? $args->{text} : $line;
    die join("\n  ","abort in state($state), event($event)"
        , "line($line)",@args)
} # _abort_event()

sub _begin_h2 {
    my ($self,$event,$line,$args) = @_;
    my $id = $args->{id} || '';
    $self->{lasttext} = [];
    print qq(<h2><a id="section-$id">$line</a></h2>\n);
} # _begin_h2()

sub _begin_h3 {
    my ($self,$event,$line,$args) = @_;
    my $id = $args->{id} || '';
    $self->{lasttext} = [];
    print qq(<h3><a id="section-$id">$line</a></h3>\n);
} # _begin_h3()

sub _begin_h4 {
    my ($self,$event,$line,$args) = @_;
    my $id = $args->{id} || '';
    $self->{lasttext} = [];
    print qq(<h4><a id="section-$id">$line</a></h4>\n);
} # _begin_h4()

sub _begin_h5 {
    my ($self,$event,$line,$args) = @_;
    my $id = $args->{id} || '';
    $self->{lasttext} = [];
    print qq(<h5><a id="section-$id">$line</a></h5>\n);
} # _begin_h5()

sub _begin_toc {
    my ($self,$event,$line,$args) = @_;
    $self->{lasttext} = [];
    print qq(<h2><a id="section-toc">$line</a></h2>\n<ul>\n);
} # _begin_toc()

sub _collect_text {
    my ($self,$event,$line,$args) = @_;
    push @{$self->{lasttext}}, $args;
    return;
} # _collect_text()

sub _end_toc_h2 {
    my ($self,$event,$line,$args) = @_;
    my $id = $args->{id} || '';
    $self->{lasttext} = [];
    print qq(</ul>\n<h2><a id="section-$id">$line</a></h2>\n);
} # _end_toc_h2()

sub _escape {
    my ($text) = @_;
    $text =~ s/</&lt;/g;
    return $text;
} # _escape()

sub _init {
    my ($self,$args) = @_;

    $self->{xmlns}  = "http://www.w3.org/1999/xhtml";
    $self->{indent} = 0;
    $self->{lasttext} = [];
    $self->{title}  = $args->{title} ? $args->{title}
                    : $self->{title} ? $self->{title}
                    :                  "You forgot to set a title"
                    ;
} # _init();

sub _print_paragraph {
    my ($self) = @_;
    my $lasttext = $self->{lasttext};
    my @lines = map { _escape($_->{text}) } @$lasttext;
    my $fl = grep { /(^[.]|[+|*]|-----|__)/ } @lines;
    my $table = grep { /___/ } @lines;

    if (0 > $#lines) {
        return;
    }
    if (0 <= $#lines
            and (0 < $fl
                and ((length(@lines) + .0) / $fl < 2
                    or 0 < $table))) {
        my $fig = "<pre>\n";
        foreach my $line (@$lasttext) {
            $fig .= " " x $line->{indent};
            $fig .= _escape($line->{text}) . "\n";
        }
        print $fig . "</pre>\n";
    }
    elsif (0 < $#lines
            and $lasttext->[0]->{indent} + 4 == $lasttext->[1]->{indent}) {
        my $first = shift @lines;
        my $class = 'term';
        my $fline = "<b>$first</b><br />";
        if ($lasttext->[0]->{text} =~ /^o   /) {
            $class = 'list';
            $fline = $first;
        }
        print join( "\n"
                  , qq(<p class="$class">)
                  , $fline
                  , @lines
                  , "</p>\n");
    }
    else {
        print join("\n", "<p>", @lines, "</p>\n");
    }
    $self->{lasttext} = [];
} # _print_paragraph()

sub _print_pre {
    my ($self) = @_;
    my @lines = map { $_->{text} } @{$self->{lasttext}};
    if (0 <= $#lines) {
        print join("\n", "<pre>", @lines, "</pre>\n");
    }
    $self->{lasttext} = [];
} # _print_pre()

sub _print_title {
    my ($self) = @_;
    my $lines = join("<br />\n", map { $_->{text} } @{$self->{lasttext}});
    $self->{lasttext} = [];
    print "<h1>$lines</h1>\n";
} # _print_title()

sub _print_tocline {
    my ($self,$event,$line,$args) = @_;
    my $id   = $args->{id};
    my $head = $args->{head};
    print qq(<li><a href="#section-$id">$id</a> $head</li>\n);
} # _print_tocline()

sub _print_toctext {
    my ($self,$event,$line,$args) = @_;
    if ($line =~ /\s*(Footnotes) \.\./
            or $line =~ /\s*(Security Considerations) \.\./
            or $line =~ /\s*(Author's Address) \.\./
            or $line =~ /\s*(Full Copyright Statement) \.\./
            or $line =~ /\s*(References) \.\./) {
        print qq(<li>$1</li>\n);
    }
    else {
        die "unknown toctext($line)";
    }
} # _print_toctext()

package main;

use Getopt::Long;
use Pod::Usage;

my %opt = (
    title => 'You forgot to set a title!',
);

my $re_app1      = qr/^([A-Z]+)\.\s+(\S.+)$/;
my $re_head1     = qr/^([0-9]+)\.\s+(\S.+)$/;
my $re_head2     = qr/^(\s{4})?([0-9A-Z]+)\.(\d+)\.?\s+(\S.+)$/;
my $re_head3     = qr/^(\s{8})?([0-9A-Z]+)\.(\d+)\.(\d+)\.?\s+(\S.+)$/;
my $re_head4     = qr/^(\s{12})?([0-9A-Z]+)\.(\d+)\.(\d+)\.(\d+)\.?\s+(\S.+)$/;
my $re_pagefoot  = qr/^(\S+)\s+(.+?)\s+\[Page (\d+)\]$/o;
my $re_pagehead  = qr/^RFC\s+(\d+)\s+(.+?)\s+(\S+\s+\d+)$/;
my $re_tocline   = qr/^\s{4}([.0-9A-Z]+)\s+(\S.+?)(\s\.*)\s(\d+)\s*$/;

my ($app1,$head1,$head2,$head3);

GetOptions( \%opt,
    'title=s',
    'help|?', 'manual')
    or pod2usage(2);

pod2usage(-exitval => 0, -verbose => 1, -input => \*DATA) if ($opt{help});
pod2usage(-exitval => 0, -verbose => 2, -input => \*DATA) if ($opt{manual});

my $fsm = RFC2XHTML::FSM->new();

$fsm->start( \%opt );

while (<>) {
    chomp;
    my $line = $_;
    
    if (/^\s*$/) {
        $fsm->event('empty', $line);
    }
    elsif (/$re_pagefoot/) {
        $fsm->event('pagefoot', $line, { author => $1, page => $3 }); 
    }
    elsif (/$re_pagehead/) {
        $fsm->event('pagehead', $line, { rfc => $1, title => $2, date => $3 }); 
    }
    elsif (/$re_tocline/) {
        $fsm->event('tocline', $line, { id => $1, head => $2, page => $4 }); 
    }
    elsif (/$re_head1/) {
        $head1 = $1;
        $head2 = 0;
        $fsm->event('head1', $line, { id => $head1, head => $2 }); 
    }
    elsif (/$re_head2/) {
        my ($indent,$h1,$h2,$head) = ($1,$2,$3);
        if ($head1 eq $h1) {
            $head2 = $h2;
            $head3 = 0;
            my $id = "$h1.$h2";
            $fsm->event('head2', $line, { id => $id, head => $head }); 
        }
        elsif (/^(\s*)(\S.*?)\s*$/) {
            my $indent = length $1;
            my $text   = $2;
            $fsm->event('text', $line, { indent => $indent, text => $text });
        }
        else {
            $fsm->event('unknown', $line);
        }
    }
    elsif (/$re_head3/) {
        my ($indent,$h1,$h2,$h3,$head) = ($1,$2,$3,$4);
        if ($head1 eq $h1
                and $head2 == $h2
                and $head3 + 1 == $h3) {
            $head3 = $h3;
            my $id = "$h1.$h2.$h3";
            $fsm->event('head3', $line, { id => $id, head => $head }); 
        }
        elsif (/^(\s*)(\S.*?)\s*$/) {
            my $indent = length $1;
            my $text   = $2;
            $fsm->event('text', $line, { indent => $indent, text => $text });
        }
        else {
            $fsm->event('unknown', $line);
        }
    }
    elsif (/$re_head4/) {
        my ($ind,$h1,$h2,$h3,$h4,$head) = ($1,$2,$3,$4,$5);
        if ($head1 eq $h1
                and $head2 == $h2
                and $head3 == $h3) {
            my $id = "$h1.$h2.$h3.$h4";
            $fsm->event('head4', $line, { id => $id, head => $head }); 
        }
        elsif (/^(\s*)(\S.*?)\s*$/) {
            my $indent = length $1;
            my $text   = $2;
            $fsm->event('text', $line, { indent => $indent, text => $text });
        }
        else {
            $fsm->event('unknown', $line);
        }
    }
    elsif (/$re_app1/) {
        $app1 = $1;
        $head1 = $1;
        $fsm->event('head1', $line, { id => $app1, head => $2 }); 
    }
    elsif (/^Status of this Memo/) {
        $fsm->event('status', $line, { id => 'status', head => $line });
    }
    elsif (/^Copyright Notice/) {
        $fsm->event('copynote', $line, { id => 'copyright', head => $line });
    }
    elsif (/^Abstract/) {
        $fsm->event('abstract', $line, { id => 'abstract', head => $line });
    }
    elsif (/^Table of Contents/) {
        $fsm->event('toc', $line, { id => 'toc', head => $line });
    }
    elsif (/^Footnotes/) {
        $fsm->event('footnotes', $line, { id => 'footnotes', head => $line });
    }
    elsif (/^References/) {
        $fsm->event('references', $line, { id => 'references', head => $line });
    }
    elsif (/^Security Considerations/) {
        $fsm->event('security', $line, { id => 'security', head => $line });
    }
    elsif (/^Author's Address/) {
        $fsm->event('author', $line, { id => 'author', head => $line });
    }
    elsif (/^Full Copyright Statement/) {
        $fsm->event('fullcopyright', $line, { id => 'fullcopyright'
                                            , head => $line });
    }
    elsif (/^(\s*)(\S.*?)\s*$/) {
        my $indent = length $1;
        my $text   = $2;
        $fsm->event('text', $line, { indent => $indent, text => $text });
    }
    else {
        $fsm->event('unknown', $line);
    }
}

$fsm->stop();

__END__

=head1 NAME

rfx2xhtml - convert plaintext RFC to XHTML

=head1 SYNOPSIS

 rfx2xhtml [options]

=head1 OPTIONS

=over 8

=item B<< -help >>

Print a brief help message and exit.

=item B<< -manual >>

Print the manual page and exit.

=back

=head1 DESCRIPTION

This program will do nothing.

=head1 AUTHOR

Mathias Weidner

