#!perl -w

package App::CamelPKI::Error;
use strict;
use base "Error";

=head1 NAME

App::CamelPKI::Error - Camel-PKI Error management

=head1 SYNOPSIS

=for My::Tests::Below "synopsis basic" begin

  use App::CamelPKI::Error;

  try {
      throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS");
  } catch App::CamelPKI::Error with {
      warn "Oops, I made a boo-boo!";
  };

=for My::Tests::Below "synopsis basic" end

=for My::Tests::Below "synopsis Class::Facet" begin

  package My::Facet;
  use Class::Facet from => "My::Object",
                   on_error => \&App::CamelPKI::Error::Privilege::on_facet_error;

=for My::Tests::Below "synopsis Class::Facet" end

=head1 DESCRIPTION

This class leverages the L<Error> module, by the excellent Graham Barr
and his buddies, to implement error management in Camel-PKI.

Unlike I<Error>, I<try>, I<with>, I<finally>, I<except> and
I<otherwise> symbols are exported by default: no need to say C<< use
Error qw(:try); >> to import these.

=cut

use Error qw(:try);
use base "Error";
use base "Exporter";
our %EXPORT_TAGS=%Error::subs::EXPORT_TAGS;
our @EXPORT_OK=map { @$_ } (values %EXPORT_TAGS);
our @EXPORT=@{$EXPORT_TAGS{try}};
{
    no warnings "once";
    *import = \&Exporter::import; # Stupid Error.pm redefines its own
                                  # ->import()
}

=head2 App::CamelPKI::Error::Internal

Thrown when a programing issue occurs (for example when not respecting the
documented API, using a bad number of arguments, ...).

=cut

package App::CamelPKI::Error::Internal;
use vars qw(@ISA); @ISA=qw(App::CamelPKI::Error);

=head2 App::CamelPKI::Error::IO

Thrown when a file issue occurs. The incriminated file name must be passed
as the parameter C<-IOfile>, for example.

=for My::Tests::Below "App::CamelPKI::Error::IO" begin

    throw App::CamelPKI::Error::IO("cannot open file",
                              -IOfile => $file);

=for My::Tests::Below "App::CamelPKI::Error::IO" end

The ->{-errorcode} field will be automatically set with the numerical
value of $!  (see L</perlvar>) when the error is thrown.  The
->{-error} field will be automatically set whith the textual value of
this same variable; note that this value depends on the active locale
and therefore should not be tested by error catching code.

=cut

package App::CamelPKI::Error::IO;
use vars qw(@ISA); @ISA=qw(App::CamelPKI::Error);

sub new {
    my $class = shift;
    local $Error::Depth = $Error::Depth + 1;
    return $class->SUPER::new(@_,
                              -errorcode => $! + 0, -error => "$!");
}

=head2 App::CamelPKI::Error::Privilege

Thrown each time the owner of a facet, another object or a class with
restricted privileges, try to exceeds those which were granted to it.
To this effect, the I<App::CamelPKI::Error::Privilege> also defines a
B<on_facet_error> function that can be installed as a L<Class::Facet>
error handler, as shown in L</SYNOPSIS>.

=cut

package App::CamelPKI::Error::Privilege;
use vars qw(@ISA); @ISA=qw(App::CamelPKI::Error);

sub on_facet_error {
    shift; # Off with the class name
    throw App::CamelPKI::Error::Privilege(-text => "Facet error", @_);
}

=head2 App::CamelPKI::Error::Database

Thrown when an Camel-PKI database (typically L<App::CamelPKI::CADB>) detects
an error at the SQL level, as an invariant violation tentative or
an insert of two values for an unique index.

=cut

package App::CamelPKI::Error::Database;
use vars qw(@ISA); @ISA=qw(App::CamelPKI::Error);

=head2 App::CamelPKI::Error::State

Thrown when a Camel-PKI object or class is in a state which cannot be handled
correctly (for example, private key and certificate already present on disk
for a non corresponding service), or an asked operation which is no yet or
anymore possible to perform (for example when L<App::CamelPKI::CA> ask for a
certificate generation when the AC key and certificate are not regulated).

=cut

package App::CamelPKI::Error::State;
use vars qw(@ISA); @ISA=qw(App::CamelPKI::Error);

=head2 App::CamelPKI::Error::OtherProcess

Thrown in case of an error in the communication with an external
process (for example failling to start an instance of
L<App::CamelPKI::SysV::Apache>).

=cut

package App::CamelPKI::Error::OtherProcess;
use vars qw(@ISA); @ISA=qw(App::CamelPKI::Error);

=head2 App::CamelPKI::Error::User

Thrown when a Camel-PKI mecanism detects an error caused by a bad user
action (or a bad usage in a web service client).

=cut

package App::CamelPKI::Error::User;
use vars qw(@ISA); @ISA=qw(App::CamelPKI::Error);


=begin internals

=head1 OVERLOADED METHODS

=cut

package App::CamelPKI::Error;

=head2 new()

Overloaded from the L</Error> parent class to activate stack traces.

=cut

sub new {
    my $self=shift;
    splice(@_,0,0,"-text") if (@_ % 2);
    my %opts=@_;

    local $Error::Debug = 1;      # activates stack traces...
    local $Carp::MaxEvalLen = 80; # ... but not too long anyway

    local $Error::Depth = $Error::Depth + 1;
    $Error::Depth += $opts{-depth} if (exists $opts{-depth});

    return $self->Error::new(%opts);
}

=head2 stringify()

Overloaded to throw a complete error trace. If this does not match
your need, feel free to trap the exception in your own code.

=cut


sub stringify {
    my ($self) = @_;
    my $retval = sprintf("%s=%s\n",
                         ref($self), $self->SUPER::stringify);
    foreach my $k (keys %$self) {
        next if ($k eq "-text" || $k eq "-stacktrace");
        local $@; # if exceptions brakes exceptions... Where do we goes?!
        my $v = eval {
            require Data::Dumper;
            local $Data::Dumper::Indent = $Data::Dumper::Indent = 1;
            local $Data::Dumper::Terse = $Data::Dumper::Terse = 1;
            Data::Dumper::Dumper($self->{$k});
        } || "<huh?>";
        $retval .= "  $k => $v";
    }
    $retval .= $self->stacktrace;
    return $retval;
}



require My::Tests::Below unless caller();
1;

__END__

use Test::More qw(no_plan);
use Test::Group;
use App::CamelPKI::Error;

test "synopsis: basics" => sub {
    my $code = My::Tests::Below->pod_code_snippet("synopsis basic");
    $code =~ s/warn/our \$foo = /g;
    eval $code; die $@ if $@;
    like(our $foo, qr/oops/i);
};

skip_next_test unless eval { require Class::Facet };
test "synopsic: Class::Facet integration" => sub {
    {
        package My::Object;
        sub new { bless {}, shift }
        sub facet { Class::Facet->make("My::Facet", shift) }
        sub nothing { 1 }
    }
    ok(My::Object->new->nothing);

    my $code = My::Tests::Below->pod_code_snippet("synopsis Class::Facet");
    eval $code; die $@ if $@;
    try {
        My::Object->new->facet->nothing;
        fail("should have thrown - Bug in Class::Facet?");
    } catch App::CamelPKI::Error::Privilege with {
        my $E = shift;
        is($E->{-text}, "Facet error");
        is($E->{-method}, "nothing");
    };
};

use Errno qw(ENOENT);
test "App::CamelPKI::Error::IO and automatic decoration" => sub {
    my $file = "/no/such_/file";
    local *BOGON;
    open(BOGON, $file);
    eval My::Tests::Below->pod_code_snippet("App::CamelPKI::Error::IO");
    my $E = $@;
    is($E->{-IOfile}, $file);
    is($E->{-errorcode}, ENOENT);
    like($E->{-error}, qr/no such file|aucun fichier/i);
};

test "stringify" => sub {
    my $less = [];
    my $E = new App::CamelPKI::Error::Internal
        (-text => "strange schmorpz",
         -schmorpz => bless {
                             zoinx => [ "is", $less ],
                             less => $less,
                            }, "Schmorpz");
    my $string = "$E";
    like($E, qr/App::CamelPKI::Error::Internal=strange schmorpz/);
    like($E, qr/strange schmorpz at /);
    like($E, qr/-line => \d+/);
    like($E, qr/bless/);
};

=end internals

=cut

