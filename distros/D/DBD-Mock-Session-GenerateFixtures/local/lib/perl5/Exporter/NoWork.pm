package Exporter::NoWork;

use 5.006;
use strict;
use warnings;

use Carp;
use Attribute::Handlers;

our $VERSION = '0.03';

my %Config;

sub import {
    my $from = shift;
    my $to   = caller;

    no strict 'refs';
    no warnings 'uninitialized';

    if ($from eq __PACKAGE__) {

        # ->isa fails on 5.6, don't know why
        my $doneISA = $] < 5.008
            ? grep $_ eq __PACKAGE__, @{"$to\::ISA"}
            : $to->isa(__PACKAGE__);

        push @{"$to\::ISA"}, __PACKAGE__ unless $doneISA;
        
        for (@_) {
            /^-MAGIC$/ and do {
                $Config{$to}{uc} = 'magic';
                next;
            };
            /^-CONSTS$/ and do {
                $Config{$to}{uc} = 'consts';
                next;
            };
            push @{$Config{$to}{default}}, $_;
        }
        return;
    }

    unless ($Config{$from}{grovelled}) {
        for (keys %{"$from\::"}) {

            if (exists &{"$from\::$_"}
                and not /^(?:IMPORT|CONFIG)$/
                and not /^_/
                and not ($Config{$from}{uc} eq 'magic' and /^[[:upper:]]+$/)
            ){
                if ($Config{$from}{uc} eq 'consts' 
                    and /^[[:upper:]_\d]+$/
                ) {
                    push @{$Config{$from}{default}}, $_;
                    push @{$Config{$from}{consts}},  $_;
                }

                push @{$Config{$from}{all}}, $_;
            }
        }   
        $Config{$from}{grovelled} = 1;
    }

    @_ or @_ = @{$Config{$from}{default}};

    $from->can('IMPORT') and @_ = $from->IMPORT(@_);

    my @todo;

    SUB:
    while (my $sub = shift) {

        # we have to do it like this, as C<local $_> doesn't work
        for ($sub) {
            /^import$/i | /^CONFIG$/ and do {
                croak "Import methods can't be imported";
                next SUB;
            };
            
            s/^:// and do {
                /^ALL$/ and do {
                    push @_, @{$Config{$from}{all}};
                    next SUB;
                };
                /^DEFAULT$/ and do {
                    push @_, @{$Config{$from}{default}};
                    next SUB;
                };
                /^CONSTS$/ and do {
                    push @_, @{$Config{$from}{consts}};
                    next SUB;
                };
            
                if ($Config{$from}{tags}{$_}) {
                    push @todo, @{$Config{$from}{tags}{$_}};
                }
                else {
                    croak qq{Tag ":$_" is not recognized by $from};
                }
                next SUB;
            };

            s/^-// and do {
                if (${"$from\::CONFIG"}{$_}) {
                    ${"$from\::CONFIG"}{$_}->($from, $_, \@_);
                }
                elsif ($from->can('CONFIG')) {
                    $from->CONFIG($_, \@_);
                }
                else {
                    croak qq{Config option "-$_" is not recognized by $from};
                }
                next SUB;
            };

            s/^\&//;
            /\W/ || /^_/ and croak qq{"$_" is not exported by $from};
            
            {
                no warnings 'uninitialized';
                /^[[:upper:]]+$/ and $Config{$from}{uc} eq 'magic'
                    and croak qq{Magic methods can't be exported};
            }
        }

        if (exists &{"$from\::$sub"}) { 
            #carp "copying \&$from\::$sub into $to";
            *{"$to\::$sub"} = \&{"$from\::$sub"};
            next SUB;
        }

        croak qq{"$sub" is not exported by $from};
    }

    for (keys %{"$from\::"}) {
        for my $ref (@todo) {
            defined &{"$from\::$_"} or next;
            #carp "ref-ifying \&$from\::$_";
            if ($ref == \&{"$from\::$_"}) {
                *{"$to\::$_"} = $ref;
            }
        }
    }
}

sub Tag : ATTR(CODE,BEGIN) {
    my ($pkg, undef, $ref, undef, $tag, undef) = @_;
    
    ref $tag or $tag = [$tag];
    for (@$tag) {
        push @{$Config{$pkg}{tags}{$_}}, $ref;
    }
}

1;

__END__

=head1 NAME

Exporter::NoWork - an easier way to export functions

=head1 SYNOPSIS

    package MyPack;

    use Exporter::NoWork -CONSTS => qw/default/;

    sub default {
        # this is exported by default
    }

    sub public {
        # this is exported on request
    }

    sub _private {
        # this is not exported
    }

    sub A_CONSTANT {
        # this is exported by default
    }

    sub tagged :Tag(tag) {
        # this is exported on the tag :tag
    }

=head1 DESCRIPTION

There is no need to add Exporter::NoWork to your @ISA: the C<use>
statement will do that for you. All functions are considered exportable,
except those beginning with an underscore, unless the option -MAGIC is
given on the C<use> line in which case functions with names in ALL CAPS
are not exportable either.

The arguments given on the C<use> line form the default import list. If
the option -CONSTS is given, all subs whose names consist of only
upper-case letters, digits and underscores will be added to the default
list as well.

Tags can be defined by giving subs the C<:Tag(tagname)> attribute. The
argument for the attribute should be a comma-separated list of tag names
to associate this sub with. Additional tags created are:

=over 4

=item :ALL

All exportable functions.

=item :DEFAULT

Those functions that would have been exported by default.

=item :CONSTS

If the -CONSTS option was given the Exporter::NoWork, this consists of
all the subs added to :DEFAULT as a result of that.

=back

In addition, any arguments given to your module which begin with a '-'
are considered to be configuration options. Exporter::NoWork will first
check the global hash %CONFIG in your package for a sub to call, and
if that fails try calling the method CONFIG in your package. In both
cases the sub will receive three arguments: your own package name, the
option name (with '-' stripped), and a reference to an array with the
rest of the arguments to your module. This is so you can shift off some
entries if your option should take arguments.

If your module defines a method IMPORT, this will be called before
anything else is done but after the default export list has been
substituted if necessary. This is expected to return a list of symbols
to export.

=head1 AUTHOR

Ben Morrow <ben@morrow.me.uk>

Please report bugs at rt.cpan.org.

=head1 COPYRIGHT

Copyright 2004 Ben Morrow. This module may be distributed under the
same terms as Perl.

=cut
