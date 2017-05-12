# $Id: Util.pm 4 2007-09-13 10:16:35Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot-model.googlecode.com/svn/trunk/lib/Class/Dot/Model/Util.pm $
# $Revision: 4 $
# $Date: 2007-09-13 12:16:35 +0200 (Thu, 13 Sep 2007) $
package Class::Dot::Model::Util;

use strict;
use warnings;
use version; our $VERSION = qv('0.1.3');
use 5.006_001;

use Carp                qw(croak);
use English             qw( -no_match_vars );
use Params::Util        qw(_ARRAY _HASHLIKE);
use Class::Plugin::Util;

my $UPLEVEL  = 2;

my %EXPORT   = (
    FQDN               => \&FQDN,
    install_coderef    => \&install_coderef,
    push_base_class    => \&push_base_class,
    run_as_call_class  => \&run_as_call_class,
);

sub import {
    my $class     = shift;
    my $call_class = caller 0;
    
    while (my ($sub_name, $sub_code_ref) = each %EXPORT) {
        install_coderef(
            $sub_code_ref => $call_class, $sub_name
        );
    }

    return;
}

sub FQDN {
    return join q{::}, @_;
}

sub install_coderef {
    my ($coderef, $package, $name) = @_;

    my $fqdn = join q{::}, $package, $name;

    NOSTRICT: {
        no strict 'refs'; ## no critic;
        *{ FQDN($package, $name) } = $coderef;
    }

    return $fqdn;
}


sub push_base_class {
    my ($base_class, $target_class) = @_;

    Class::Plugin::Util::_require_class($base_class); ## no critic

    if (! $target_class->isa($base_class)) {
        no strict 'refs'; ## no critic
        push @{ FQDN($target_class, 'ISA') }, $base_class;
    }

    run_as_call_class({
        call_class => $target_class,
        class     => $base_class,
        method    => 'import'
    });

    return;
}

sub run_as_call_class { ## no critic
    my $class;
    my $method;
    my $call_class;

    if (_HASHLIKE($_[0])) {
        my $opts      = shift;
        $class        = $opts->{class};
        $method       = $opts->{method};
        $call_class   = $opts->{call_class};
    }
    else {
        $call_class   = shift;
        $method       = shift;
        $class        = $call_class;
    }

    my $statement = qq{
        package $call_class;
        \$call_class->\$method(\@_);
    }; ## no critic

    eval qq{ $statement }; ## no critic

    if ($EVAL_ERROR) {
        no warnings 'once'; ## no critic
        $Carp::CallLevel = $UPLEVEL; ## no critic
        croak $EVAL_ERROR;
    }

    return;
}

1;

__END__

=begin wikidoc

= NAME

Class::Dot::Model::Util - Private utility functions.

= VERSION

This document describes Class::Dot::Model version v%%VERSION%%

= SYNOPSIS

    # No user servicable parts inside...


= DESCRIPTION

No user serviceable parts inside.

= SUBROUTINES/METHODS

== SUBROUTINES

=== {install_coderef($coderef => $into_class, $method_name)}

Install subroutine into a class with custom name.

Example:

    use Class::Dot::Model qw(install_coderef);
    install_coderef(sub { print "hello world" }, "Hello::World", "hello");

    # prints: "hello world".
    Hello::World->hello();

=== {push_base_class($the_class, $class_target)}

Push a base class into a target class.

Example:

    push_base_class('DBIx::Class',  'MyApp::Model');

Is the same as:

    push @MyApp::Model::ISA, 'DBIx::Class';

    {
        package MyApp::Model;
        DBIx::Class->import();
    }
    

=== {run_as_call_class(($callclass, $method, @arguments) | %options_ref)}

Run a method in a class, but make it look like another class runs it.

Example:

    package Simpsons::Homer;

    sub doh {
        my $caller = caller 0;
        print "$caller: Doh!\n";
    }

    run_as_call_class({
        callclass => 'Hello::World',    - the class to take we're in.
        class     => 'Simpsons::Homer',  - the class that has the method to call.
        method    => 'hello'            - the method to call.
    });

Gives the output:

    Hello::World: Doh!

Because it's basicly the same as writing:

    package Simpsons::Homer;
    
    sub doh {
        my $caller = caller 0;
        print "$caller: Doh!\n";
    }

    package Hello::World;
    Simpsons::Homer->doh();

    package Simpsons::Homer;

    # resume other work.
    
   
There is also a shortcut method of calling this function if you want to run a
method in the callclass itself:

    package Hello::World;
    run_as_callclass('Simpsons::Homer', 'doh');

Gives the output:

    Simpsons::Homer: Doh!


=== {FQDN(@class_components)}

Return a valid Perl class name out of a list of class components.

Example:

    FQDN('Class', 'Plugin', 'Util')

Becomes

    Class::Plugin::Util

= DIAGNOSTICS

None.

= CONFIGURATION AND ENVIRONMENT

This module uses no external configuration or environment variables.

= DEPENDENCIES

* [DBIx::Class]

* [Class::Dot]

* [Class::Plugin::Util]

* [Params::Util]

* [Config::PlConfig]

* [version]

= INCOMPATIBILITIES

None known.

= BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
[bug-class-dot-model@rt.cpan.org|mailto:class-dot-model@rt.cpan.org], or through the web interface at
[CPAN Bug tracker|http://rt.cpan.org].

= SEE ALSO

== [Class::Dot::Model]

== [DBIx::Class]

== [Class::Dot]

== [DBIx::Class::Relationships]

== [DBIx::Class::Manual::Cookbook]

= AUTHOR

Ask Solem, [ask@0x61736b.net].

= LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem [ask@0x61736b.net|mailto:ask@0x61736b.net].

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

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

=for stopwords expandtab shiftround
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
