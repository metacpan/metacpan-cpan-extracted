#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 3;

# taken from Class::Accessor::Complex
package Foo;
use parent qw(Class::Accessor::Installer);

sub mk_new {
    my ($self, @args) = @_;
    my $class = ref $self || $self;
    @args = ('new') unless @args;
    for my $name (@args) {
        $self->install_accessor(
            name => $name,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${name}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;

                # don't use $class, as that's already defined above
                my $this_class = shift;
                my $self = ref($this_class) ? $this_class : bless {},
                  $this_class;
                my %args =
                  (scalar(@_ == 1) && ref($_[0]) eq 'HASH')
                  ? %{ $_[0] }
                  : @_;
                $self->$_($args{$_}) for keys %args;
                $self->init(%args) if $self->can('init');
                $self;
            },
            purpose => <<'EODOC',
Creates and returns a new object. The constructor will accept as arguments a
list of pairs, from component name to initial value. For each pair, the named
component is initialized by calling the method of the same name with the given
value. If called with a single hash reference, it is dereferenced and its
key/value pairs are set as described before.
EODOC
            example => [
                "my \$obj = $class->$name;",
                "my \$obj = $class->$name(\%args);",
            ],
        );
    }
    $self;    # for chaining
}

sub mk_scalar_accessors {
    my ($self, @fields) = @_;
    my $class = ref $self || $self;
    for my $field (@fields) {
        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                return $_[0]->{$field} if @_ == 1;
                $_[0]->{$field} = $_[1];
            },
            purpose => <<'EODOC',
A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.
EODOC
            example =>
              [ "my \$value = \$obj->$field;", "\$obj->$field(\$value);", ],
        );
        for my $name ("clear_${field}", "${field}_clear") {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    $_[0]->{$field} = undef;
                },
                purpose => <<'EODOC',
Clears the value.
EODOC
                example => "\$obj->$name;",
            );
        }
    }
    $self;    # for chaining
}

package Test01;
use parent -norequire, 'Foo';
__PACKAGE__->mk_new->mk_scalar_accessors(qw(name));

package main;
can_ok(
    'Test01', qw(
      new name name_clear clear_name
      )
);
my $test01 = Test01->new(name => 'Shindou Hikaru');
is($test01->name, 'Shindou Hikaru', 'set name');
$test01->clear_name;
is($test01->name, undef, 'cleared name');
