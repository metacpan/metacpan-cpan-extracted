# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
package Acme::Locals;

use strict;
use warnings;
use version; our $VERSION = qv('0.1.1');
use 5.00600;

use Carp            qw(carp croak);
use PadWalker       ();
use Params::Util    qw(_SCALAR _ARRAY);

BEGIN {
    use English qw(-no_match_vars);
    my $find_best_say = sub {
        eval q{use Perl6::Say}; ## no critic
        return if not $EVAL_ERROR;
        no warnings 'once'; ## no critic
        *say = sub { print @_, "\n" };
    };
    $find_best_say->();
}

my $DEFAULT_FORMAT = q{%s};
my $DEFAULT_MODE   = '-python';

my %EXPORT_OK      = (
    sayx     => \&sayx,
    printx   => \&printx,
    sprintx  => \&sprintx,
    locals   => \&locals,
    globals  => \&globals,
    lexicals => \&lexicals,
);

my %EXPORT_TAGS    = (
    ':all'  => [ keys %EXPORT_OK ],
);

my %MODES = (
    '-python' => qr/\%\( (.+?) \)(\w)?/xms,
    '-ruby'   => qr/\#\{ (.+?) \}/xms,
);

my %mode_for_class;

sub sayx        ($@); ## no critic
sub printx      ($@); ## no critic
sub sprintfx    ($@); ## no critic

sub import {
    my ($this_class, @tags) = @_;
    my $call_class = caller 0;

    my @to_export;
    for my $tag (@tags) {
        if ($tag =~ m/^:/xms) {
            croak __PACKAGE__, " does not support the tag  $tag"
                if not exists $EXPORT_TAGS{$tag};

            push @to_export, @{ $EXPORT_TAGS{$tag} };
        }
        elsif ($tag =~ m/^-/xms) {
            $mode_for_class{$call_class} = $tag;
        }
        else {
            push @to_export, $tag;
        }
    }
    $mode_for_class{$call_class} ||= $DEFAULT_MODE;
    if (not exists $MODES{ $mode_for_class{$call_class} }) {
        my $cur_mode = $mode_for_class{$call_class};
        carp "Unknown mode $cur_mode. Switching to default mode $DEFAULT_MODE";
        $mode_for_class{$call_class} = $DEFAULT_MODE;
    }

    no strict 'refs'; ## no critic
    for my $export_sub (@to_export) {
        croak __PACKAGE__, " does not export $export_sub"
            if not exists $EXPORT_OK{$export_sub};
    
        *{ $call_class . "::$export_sub" } = $EXPORT_OK{$export_sub};
    }

    return;
}

sub sayx ($@){ ## no critic
    say sprintx([caller 0], @_);
}

sub printx ($@) { ## no critic
    print sprintx([caller 0], @_);
}

sub sprintx ($@) { ## no critic
    my $peek_level = 1;
    my $call_class;
    if (_ARRAY( $_[0] )) {
        $call_class = shift->[0];
        $peek_level++;
    }
    $call_class ||= caller 0;

    my ($fmt, %bind_vars) = @_;

    my @binds;
    my $map_bind_var = sub {
        my ($bind_var_name, $format_char) = @_;
        local *__ANON__ = 'map_bind_var'; ## no critic

        my $internal_name = $bind_var_name;
        if (exists $bind_vars{$internal_name}) {
            # pass
        }
        elsif (exists $bind_vars{q{$}.$internal_name}) {
            $internal_name = q{$}.$internal_name;
        }
        else {
            croak "No such bind var: $bind_var_name";
        }

        my $value_ref = $bind_vars{$internal_name};
        croak 'Bind var must be scalar'
            if not _SCALAR($value_ref);

        push @binds, ${ $value_ref };

        return defined $format_char ? q{%} . $format_char
                                    : $DEFAULT_FORMAT;
    };

    my $mode = $mode_for_class{$call_class} || $DEFAULT_MODE;
    my $re   = $MODES{ $mode };

    if ($mode eq '-ruby' && !scalar keys %bind_vars) {
        %bind_vars = %{ PadWalker::peek_my($peek_level) };
    }
    
    $fmt =~ s/$re/$map_bind_var->($1, $2)/xmseg;

    return sprintf $fmt, @binds;
}

sub lexicals {
    goto &locals;
}

sub locals {
    return wantarray ? %{ PadWalker::peek_my(1) }
                     :    PadWalker::peek_my(1);
}

sub globals {
    return wantarray ? %{ PadWalker::peek_our(1) }
                     :    PadWalker::peek_our(1);
}

1;

__END__

=begin wikidoc

= NAME

Acme::Locals - Interpolate like Python/Ruby.

= VERSION

This document describes Acme::Locals version v0.0.1

= SYNOPSIS

    # Python mode

    use Acme::Locals qw(-python :all);

    sub foo {
        my $x   = 10;
        my $y   = 100;
        my $who = "world";
        sayx '%(x)d %(y)d hello %(who)s!', locals();
    }


    # Ruby mode

    use Acme::Locals qw(-ruby :all);

    sub bar {
        my $x   = 10;
        my $y   = 100;
        my $who = "world";

        sayx '#{x} #{y} hello #{who}';
    }


= DESCRIPTION

This module let's you interpolate like Python and Ruby.

= SUBROUTINES/METHODS

== CLASS METHODS

=== {sayx $format @fmt_vars}

print/puts like python/ruby.

=== {printx $format @fmt_vars}

printf like python/ruby.

=== {sprintx $format @fmt_vars}

sprintf like python/ruby.

=== {locals()}

Return a hash of all lexical variables in the current scope. (Using
PadWalker).

=== {globals()}

Return a hash of all global variables. (Using PadWalker).

=== {lexicals()}

Alias to {locals()}

== PRIVATE CLASS METHODS


= DIAGNOSTICS


= CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

= DEPENDENCIES

* [version]

* [PadWalker]

* [Params::Util]

= INCOMPATIBILITIES

None known.

= BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
[bug-acme-locals@rt.cpan.org|mailto:bug-acme-locals@rt.cpan.org], or through the web interface at
[CPAN Bug tracker|http://rt.cpan.org].

= SEE ALSO

= AUTHOR

Ask Solem, [ask@0x61736b.net].

with thanks to sverrej for inspiration :)

= LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem [ask@0x61736b.net|mailto:ask@0x61736b.net].

{Acme::Locals} is distributed under the Modified BSD License.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. The name of the author may not be used to endorse or promote products derived
from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

= DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=end wikidoc

=for stopwords vim expandtab shiftround

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
