#+##############################################################################
#                                                                              #
# File: Authen/Credential.pm                                                   #
#                                                                              #
# Description: abstraction of a credential                                     #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Authen::Credential;
use strict;
use warnings;
our $VERSION  = "1.2";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);
use Params::Validate qw(validate_with validate_pos :types);
use URI::Escape qw(uri_escape uri_unescape);

#
# global variables
#

our(
    $_IdRe,           # regexp matching an identifier
    $_ValChars,       # set of all allowed value characters
    $_SepChars,       # set of all allowed separator characters
    %_LoadedModule,   # hash of successfully loaded modules
    %ValidationSpec,  # per-scheme Params::Validate specification
    %Preparator,      # per-scheme and target preparator code
);

$_IdRe = qr{[a-z][a-z0-9]*};
$_ValChars = q{a-zA-Z0-9/\-\+\_\~\.\:};
$_SepChars = q{\,\ };

#+++############################################################################
#                                                                              #
# helper functions                                                             #
#                                                                              #
#---############################################################################

#
# make sure a module is loaded
#

sub _require ($) {
    my($module) = @_;

    return if $_LoadedModule{$module};
    eval("require $module"); ## no critic 'ProhibitStringyEval'
    if ($@) {
        $@ =~ s/\s+at\s.+?\sline\s+\d+\.?$//;
        dief("failed to load %s: %s", $module, $@);
    } else {
        $_LoadedModule{$module} = 1;
    }
}

#
# check that the data matches the per-scheme specification
#

sub _check ($@) {
    my($scheme);

    $scheme = shift(@_);
    dief("invalid credential scheme (missing validation spec): %s", $scheme)
        unless $ValidationSpec{$scheme};
    return(validate_with(
        params => \@_,
        spec => {
            %{ $ValidationSpec{$scheme} },
            scheme => {
                type    => SCALAR,
                regex   => qr/^\Q$scheme\E$/,
                default => $scheme,
            },
        },
        stack_skip => 2,
    ));
}

#+++############################################################################
#                                                                              #
# object oriented interface                                                    #
#                                                                              #
#---############################################################################

#
# constructors
#

sub new : method {
    my($class, %option, $cc, $scheme);

    $class = shift(@_);
    if ($class eq __PACKAGE__) {
        # toplevel constructor
        %option = validate_with(
            params => \@_,
            spec => {
                scheme => {
                    type    => SCALAR,
                    regex   => $_IdRe,
                    default => "none",
                },
            },
            allow_extra => 1,
        );
        $cc = $class . "::" . $option{scheme};
        _require($cc);
        return($cc->new(\%option));
    }
    # inherited constructor
    $scheme = substr($class, length(__PACKAGE__) + 2);
    return(bless({ _check($scheme, @_) }, $class));
}

sub parse : method {
    my($class, $string, @list, %option);

    $class = shift(@_);
    validate_pos(@_, { type => SCALAR })
        unless @_ == 1 and defined($_[0]) and ref($_[0]) eq "";
    $string = shift(@_);
    return($class->new()) if $string eq "";
    dief("invalid credential string: %s", $string)
        unless $string =~ /^[${_ValChars}${_SepChars}\%\=]+$/o;
    @list = split(/[${_SepChars}]+/o, $string);
    dief("invalid credential string: %s", $string)
        unless @list and $list[0] =~ /^($_IdRe)$/o;
    %option = (scheme => shift(@list));
    foreach my $kv (@list) {
        if ($kv =~ /^($_IdRe)\=([$_ValChars\%]*)$/o) {
            dief("duplicate credential key: %s", $1)
                if exists($option{$1});
            $option{$1} = uri_unescape($2);
        } else {
            dief("invalid credential key=value: %s", $kv);
        }
    }
    return($class->new(\%option));
}

#
# transformers
#

sub hash : method {
    my($self);

    $self = shift(@_);
    validate_pos(@_) if @_;
    return($self) unless wantarray();
    return(%{ $self });
}

sub string : method {
    my($self, @parts);

    $self = shift(@_);
    validate_pos(@_) if @_;
    dief("invalid credential: no scheme") unless $self->{scheme};
    @parts = ($self->{scheme});
    foreach my $key (sort(keys(%{ $self }))) {
        next if $key eq "scheme";
        push(@parts, $key . "=" . uri_escape($self->{$key}, "^$_ValChars"));
    }
    return(join(" ", @parts));
}

#
# accessors
#

foreach my $name (qw(scheme)) {
    no strict "refs";
    *{ $name } = sub {
        my($self);
        $self = shift(@_);
        validate_pos(@_) if @_;
        return($self->{$name});
    };
}

#
# generic check method using the Params::Validate specification
#

sub check : method {
    my($self);

    $self = shift(@_);
    validate_pos(@_) if @_;
    return(_check($self->scheme(), $self));
}

#
# generic prepare method using the declared preparators
#

sub prepare : method {
    my($self, $target, $preparator);

    $self = shift(@_);
    validate_pos(@_, { type => SCALAR })
        unless @_ == 1 and defined($_[0]) and ref($_[0]) eq "";
    $target = shift(@_);
    $preparator = $Preparator{$self->scheme()}{$target};
    return($preparator->($self)) if $preparator;
    dief("invalid %s credential preparation target: %s",
         $self->scheme(), $target);
}

1;

__DATA__

=head1 NAME

Authen::Credential - abstraction of a credential

=head1 SYNOPSIS

  use Authen::Credential;
  use Authen::Credential::plain;
  use Getopt::Long qw(GetOptions);
  use Config::General qw(ParseConfig);
  use HTTP::Request;

  # creation
  $cred = Authen::Credential->new(
      scheme => "plain",
      name   => "system",
      pass   => "manager",
  );
  # idem directly using the sub-class
  $cred = Authen::Credential::plain->new(
      name   => "system",
      pass   => "manager",
  );

  # get credential from command line option
  GetOptions(\%Option,
      "auth=s",
      ...
  );
  $cred = Authen::Credential->parse($Option{auth});

  # get credential from configuration file
  %Option = ParseConfig(-ConfigFile => "...");
  $cred = Authen::Credential->new($Option{auth});

  # access the credential attributes
  if ($cred->scheme() eq "plain") {
      printf("user name is %s\n", $cred->name());
  }

  # use the prepare() method to get ready-to-use data
  $req = HTTP::Request->new(GET => $url);
  $req->header(Authorization => $cred->prepare("HTTP.Basic"));

=head1 DESCRIPTION

This module offers abstractions of credentials, i.e. something that
can be used to authenticate. It allows the creation and manipulation of
credentials. In particular, it defines a standard string representation
(so that credentials can be given to external programs as command line
options), a standard structured representation (so that credentials can
be stored in structured configuration files or using JSON) and
"preparators" that can transform credentials into ready-to-use data for
well known targets.

Different authentication schemes (aka credential types) are supported.
This package currently supports C<none>, C<plain> and C<x509> but others
can be added by providing the supporting code in a separate module.

A Python implementation of the same credential abstractions is available
at L<https://github.com/cern-mig/python-auth-credential> so credentials
can be shared between different programming languages.

For a given scheme, a credential is represented by an object with a
fixed set of string attributes. For instance, the C<plain> scheme has
two attributes: C<name> and C<pass>. More information is provided by
the scheme specific module, for instance L<Authen::Credential::plain>.

=head1 STRING REPRESENTATION

The string representation of a credential is made of its scheme
followed by its attributes as key=value pairs, seperated by space.

For instance, for the C<none> scheme with no attributes:

  none

And the the C<plain> scheme with a name and password:

  plain name=system pass=manager

If needed, the characters can be URI-escaped, see L<URI::Escape>. All
non-alphanumerical characters should be escaped to avoid parsing
ambiguities.

The string representation is useful to give a program through its
command line options. For instance:

  myprog --uri http://foo:80 --auth "plain name=system pass=manager"

=head1 STRUCTURED REPRESENTATION

The structured representation of a credential is made of its scheme
and all its attributes as a string table.

Here is for instance how it could end up using JSON:

  {"scheme":"plain","name":"system","pass":"manager"}

The same information could be stored in a configuration file. Here is
an example using the Apache syntax, which is for instance supported by
L<Config::General>:

  <auth>
    scheme = plain
    name   = system
    pass   = manager
  </auth>

=head1 METHODS

This module supports the following methods:

=over

=item new([OPTIONS])

return a new credential object (class method); the OPTIONS are its
attributes

=item parse(STRING)

return a new credential object from its string representation (class
method)

=item hash()

return its structured representation as a reference to a hash

=item string()

return its string representation

=item check()

check that the credential contains the expected attributes

=item prepare(TARGET)

use the credential to prepare data for a given target (this is scheme
specific)

=item scheme()

return the authentication scheme of the credential

=back

In addition, the attributes can be accessed using eponymous methods.
See the example in the L</"SYNOPSIS"> section.

=head1 SEE ALSO

L<Authen::Credential::none>,
L<Authen::Credential::plain>,
L<Authen::Credential::x509>,
L<URI::Escape>,

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2011-2015
