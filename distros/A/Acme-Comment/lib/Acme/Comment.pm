package Acme::Comment;

use strict;
use Filter::Simple;

BEGIN {
    use vars qw($VERSION);
    $VERSION    =   '1.04';
}

my $TypeCount = 0;
my $Type = 'C';
my $Conf;

{   no warnings;
    $Conf = {
        C   => {
            own_line    => 1,
            start       => quotemeta '/*',
            end         => quotemeta '*/',
            one_line    => 0,
        },
        HTML    => {
            own_line    => 1,
            start       => quotemeta '<!--',
            end         => quotemeta '-->',
            one_line    => 0,
        },
        RUBY    => {
            own_line    => 1,
            start       => quotemeta '=begin',
            end         => quotemeta '=end',
            one_line    => 0,
            single      => '#',
        },
        JAVA    => {
            own_line    => 1,
            start       => quotemeta '/*',
            end         => quotemeta '*/',
            one_line    => 0,
            single      => quotemeta '//',
        },
        PASCAL  => {
            own_line    => 1,
            start       => quotemeta '(*',
            end         => quotemeta '*)',
            one_line    => 0,
        },

        ALGOL  => {
            own_line    => 1,
            start       => quotemeta "'comment'",
            end         => quotemeta ';',
            one_line    => 0,
        },

        HUGO    => {
            own_line    => 1,
            start       => quotemeta '!\\',
            end         => quotemeta '\!',
            one_line    => 0,
            single      => '!(?!\\\\)',
        },

        BASIC   =>  {
            single      =>  q['],
        },
        PILOT   =>  {
            single      => quotemeta '\/\/',
        },
        BLUE   =>  {
            single      => '(?:==)|(?:--)',
        },

        INTERCAL    => {
            single  => '(?:\(\d+\)\s*)?DO NOTE THAT',
        },
        FORTRAN     => {
            single  => quotemeta '!',
        },
        PERL        => {
            single      => quotemeta q[#],
        },
        ALAN        => {
            single      => "--",
        },
        ORTHOGONAL  => {
            single      => quotemeta ";",
        },
        FOCAL  => {
            single      => "comment",
        },
        LATEX  => {
            single      => quotemeta "%",
        },
        FOXBASE => {
            single      => '(?:\*)|(?:&&)',
        }
    };


    ### the comment styles for ADA and Basic are the same ###
    for my $type(qw|ADA|)                               { $Conf->{$type} = $Conf->{'BASIC'} }

    for my $type(qw|POSTSCRIPT|)                        { $Conf->{$type} = $Conf->{'LATEX'} }

    for my $type(qw|ADVSYS LISP SCHEME|)                { $Conf->{$type} = $Conf->{'ORTHOGONAL'} }

    for my $type(qw|EIFFEL HASKELL|)                    { $Conf->{$type} = $Conf->{'ALAN'} }

    for my $type(qw|BETA BLISS JOY VAR'AQ|)             { $Conf->{$type} = $Conf->{'PASCAL'} }

    for my $type(qw|B PL/I CHILL|)                      { $Conf->{$type} = $Conf->{'C'} }

    for my $type(qw|C++ PHP C# CLEAN ELASTIC GUILE|)    { $Conf->{$type} = $Conf->{'JAVA'} }

    for my $type(qw|PYTHON PARROT AWK UNLAMBDA E ICON|) { $Conf->{$type} = $Conf->{'PERL'} }
}

sub import {
    my $package = shift;
    my %args    = @_;

    if(@_%2){
        die "Incomplete set of arguments to $package\n"
    }

    ### see if there are any arguments, if not, we default to the C comment style ###
    if( keys %args ) {

        ### check if the user requested a certain type of comments ###
        if( $args{type} ) {

            ### and check if it even exists ###
            if( $Conf->{ uc $args{type} } ) {
                $Type = uc $args{type};

                $Conf->{$Type}->{own_line} = $args{own_line} if defined $args{own_line};
                $Conf->{$Type}->{one_line} = $args{one_line} if defined $args{one_line};

            ### otherwise die with an error ###
            } else {
                die "Requested an unsupported type $args{type} for Acme::Comment\n";
            }

        ### otherwise, define a new type for the user ###
        } else {
            $Type = ++$TypeCount;

            unless( (defined $args{start} and defined $args{end}) or defined $args{single} ) {
                die "You need to specify both start and end tags OR a single line comment!\n";
            } else {
                if( defined $args{start} and defined $args{end} and $args{start} eq $args{end} ) {
                    die "Start and end tags must be different!\n";
                }

                $Conf->{$TypeCount}->{start}    = quotemeta($args{start})  if defined $args{start};
                $Conf->{$TypeCount}->{end}      = quotemeta($args{end})    if defined $args{end};
                $Conf->{$TypeCount}->{single}   = quotemeta($args{single}) if defined $args{single}
            }

            $Conf->{$TypeCount}->{own_line} = defined $args{own_line}
                                                ? $args{own_line}
                                                : 1;

            $Conf->{$TypeCount}->{one_line} = defined $args{one_line}
                                                ? $args{one_line}
                                                : 0;

        }

    ### no arguments, Let's take the default C comment style ###
    }
}

sub parse {

    #use Data::Dumper;
    #print scalar @_;
    #die Dumper \@_;

    my $str = shift;

    my $start   = $Conf->{$Type}->{start}     if $Conf->{$Type}->{start};
    my $end     = $Conf->{$Type}->{end}       if $Conf->{$Type}->{end};
    my $single  = $Conf->{$Type}->{single}    if $Conf->{$Type}->{single};

    my ($rdel,$ldel);
    my ($roneline, $loneline);

    if( $start && $end ) {
        ### having the comments on their own line is recommended
        ### to avoid ambiguity -kane
        $roneline = '\s*' . $end . '\s*$';
        $loneline = '^\s*' . $start . '\s*';

        if( $Conf->{$Type}->{own_line} ){
            $rdel = '^' . $roneline;
            $ldel = $loneline . '$';
        } else {
            $rdel = $roneline;
            $ldel = $loneline;
        }
    }

    ### loop counter ###
    my $i;

    ### tag counter ###
    my $counter;

    ### line number of the last found comment open ###
    my $lastopen;

    ### return value container ###
    my @return;

    for my $line (split/\n/, $str) {
        ### increase line counter ###
        $i++;

        ### if there is a single line comment available ##
        if($single) {
            if( $line =~ m|^\s*$single| ) {
    	        push @return, "";
    	    	next;
	        }
        }

        ### check if we have multiline comment options ###
        if($roneline && $loneline) {
            ### check if we are allowed to have comments on one line
            ### and if so, see if they match
            if( $Conf->{$Type}->{one_line} ) {
                if( $line =~ /$loneline.*?$roneline/) {
		            push @return, "";
                    next;
                }
            }

            ### if we find an opening tag, add to the counter
            ### and mark the line number
            if( $line =~ /$ldel/ ) {
                $lastopen = $i;
                $counter++;
		        push @return, "";
                next;

            ### if we find a closing tag, decreate the counter
            ### if counter was already at zero, there's a syntax error
            } elsif ( $line =~  /$rdel/ ) {
                unless($counter) {
                    die "Missing opening comment for closing comment on line $i\n";
                }
                $counter--;
		        push @return, "";
                next;
            }
        }

        ### if we have a counter, we're still inside a comment
        ### so dont add it then.. if the line is just whitespace
        ### we might as well ingore it too
        unless($counter or $line =~ /^\s*$/) {
            push @return, $line ;
            next;
        } else {
		    push @return, "";
		    next;
	    }
    }

    ### if we have a counter left after parsing all the lines
    ### we must have an opening tag (or more) that dont have a closing tag
    if($counter){ die "No closing bracket found for opening comment at line $lastopen\n" }

    ### Filter::Simple demands we return $_ ###
    $_ = join "\n", @return;

    return $_;
}

sub _gimme_conf { return $Conf };

FILTER_ONLY executable => sub { parse($_); };


1;

=pod

=head1 NAME

Acme::Comment

=head1 SYNOPSIS

    use Acme::Comment type=>'C++', own_line=>1;

    /*
    if (ref $mod) {
        $bar->{do}->blat(msg => 'blarg');
        eval {

    i'm sooo sick of this time for some coffee

    */

    // I prefer beer.  --sqrn

=head1 DESCRIPTION

Acme::Comment allows multi-line comments which are filtered out.
Unlike the pseudo multi-line comment C<if (0) {}>, the code being
commented out need not be syntactically valid.

=head1 USE

Acme::Comment contains several different commenting styles.

Styles may be specified by the C<types> argument, or by C<start> and
C<end> and manipulated with C<own_line> and C<one_line>.

Styles may contain multi-line comments and single-line comments.
Perl, for example, has single-line comments in the form of C<#>.

C, on the other hand, has multi-line comments which begin with
C</*> and end with C<*/>.

With multi-line comments, leaving out a begin or an end comment
will cause an error.

Both types of comments may only be preceded on a line by whitespace.

=head2 own_line

By default, C<own_line> is true, which means that multi-line comments may not
be followed by any characters other than whitespace on the same line.
This is the safest option if you think your code may contain the
comment characters (perhaps in a regex).  If you disable it, other
characters are allowed on the line after the starting delimiter, but these
characters will be ignored.  The closing delimiter cannot be followed by
any other characters.

Thus, in the following example, C<$foo> would be set to 1.

    /* This is my real comment.
    */
    $foo = 1;

If you wish to change this option, you must specify either a C<type> or
C<start> and C<end>.

=head2 one_line

By default, this is set to false, which means that multi-line comments
may not end on the same line in which they begin.  Turning this on
allows the following syntax:

    /* comment */

If you wish to change this option, you must specify either a C<type> or
C<start> and C<end>.

=head2 C<start> and C<end>

The C<start> and C<end> arguments allow you to supply your own commenting
pattern instead of one of the ones available with C<type>.  It is not
valid to provide the same pattern for both C<start> and C<end>.

You cannot specify both C<type> and C<start> and C<end>, and C<start>
and C<end> must both be provided if you provide one of them.

=head2 types

The C<types> argument specifies what language style should be used.
Only one language style may be specified.

=over 4

=item * Ada

Single-line comments begin with C<'>.

=item * Advsys

Advsys single-line comments begin with C<;>.

=item * Alan

Single-line comments start with C<-->.

=item * Algol

Multi-line comments begin with C<'comment'> and end with C<;>.

NOTE: You should not use Algol with C<own_line> set to 0:
The source filter will take a C<;> to be an ending tag for your
comments, regardless of where it is.

=item * AWK

Single-line comments use C<#>.

=item * B

Multi-line comments use C</*> and C<*/>.

=item * Basic

Single-line comments begin with C<'>.

=item * Beta

Multi-line comments use C<(*> and C<*)>.

=item * Bliss

Multi-line comments use C<(*> and C<*)>.

=item * Blue

Single-line comments use either C<==> or C<-->.

=item * C

The default for Acme::Comment is C-style multi-line commenting
with C</*> and C<*/>.  However, if you wish to change C<one_line>
or C<own_line>, you must explicitly specify the type.

=item * C++

C++ multi-line style uses C</*> and C<*/>.  Single-line uses C<//>.

=item * C#

C# multi-line style uses C</*> and C<*/>.  Single-line uses C<//>.

=item * Chill

Multi-line comments use C</*> and C<*/>.

=item * Clean

Clean multi-line style uses C</*> and C<*/>.  Single-line uses C<//>.

=item * E

Single-line comments use C<#>.

=item * Eiffel

Single-line comments start with C<-->.

=item * Elastic

Elastic multi-line style uses C</*> and C<*/>.  Single-line uses C<//>.

=item * Focal

Single-line comments start with C<comment>.

=item * Fortran

Single-line comments use C<!>.

=item * Guile

Guile multi-line style uses C</*> and C<*/>.  Single-line uses C<//>.

=item * Haskell

Single-line comments start with C<-->.

=item * HTML

HTML style has multi-line commenting in the form of C<E<lt>!--> and
C<--E<gt>>.

=item * Hugo

Multi-line comments begin with C<!\> and end with C<\!>.  Single-line
comments are not implemented due to their similarity with multi-line
comments.

=item * Icon

Single-line comments use C<#>.

=item * Intercal

Single-line comments are marked with C<DO NOTE THAT> and may optionally
be preceded by a line number in the following syntax:
C<(23) DO NOTE THAT>.

=item * Java

Java multi-line style uses C</*> and C<*/>.  Single-line uses C<//>.

=item * Joy

Multi-line comments use C<(*> and C<*)>.

=item * LaTeX

Single-line comments use C<%>.

=item * LISP

LISP single-line comments begin with C<;>.

=item * Orthogonal

Orthogonal single-line comments begin with C<;>.

=item * Parrot

Single-line comments use C<#>.

=item * Pascal

Multi-line comments use C<(*> and C<*)>.

=item * Perl

Single-line comments use C<#>.

=item * PHP

PHP multi-line style uses C</*> and C<*/>.  Single-line uses C<//>.

=item * Pilot

Single-line comments in the syntax C<\/\/> are supported.

=item * PL/I

Multi-line comments use C</*> and C<*/>.

=item * PostScript

Single-line comments use C<%>.

=item * Python

Single-line comments use C<#>.

=item * Ruby

Ruby multi-line comments begin with C<=begin> and end with
C<=end>.  Single-line comments use C<#>.

=item * Scheme

Scheme single-line comments begin with C<;>.

=item * Unlambda

Single-line comments use C<#>.

=item * Var'aq

Multi-line comments use C<(*> and C<*)>.

=back

=head1 CAVEATS

Because of the way source filters work, it is not possible to eval
code containing comments and have them correctly removed.

=head1 NOTE

Some of these programming languages may be spelled incorrectly, or
may have the wrong quote characters noted.  The majority of this
information was found by searches for language specifications.

So please report errors, as well as obscure commenting syntax you
know of.

=head1 Acknowledgements

Thanks to Abigail and Glenn Maciag for their suggestions.

=head1 BUG REPORTS

Please report bugs or other issues to E<lt>bug-acme-comment@rt.cpan.orgE<gt>.

=head1 AUTHOR

This module by Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

This library is free software; you may redistribute and/or modify it 
under the same terms as Perl itself.

=cut
