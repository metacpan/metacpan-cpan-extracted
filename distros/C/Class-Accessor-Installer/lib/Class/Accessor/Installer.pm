use 5.006;
use warnings;
use strict;

package Class::Accessor::Installer;
our $VERSION = '1.100880';

# ABSTRACT: Install an accessor subroutine
use Sub::Name;
use UNIVERSAL::require;

sub install_accessor {
    my ($self, %args) = @_;
    my ($package, $name, $code) = @args{qw(package name code)};
    unless (defined $package) {
        $package = ref $self || $self;
    }
    $name = [$name] unless ref $name eq 'ARRAY';
    my @caller;
    if ($::PTAGS) {
        my $level = 1;
        do { @caller = caller($level++) }
          while $caller[0] =~ /^Class(::\w+)*::Accessor::/o;
    }
    for my $sub (@$name) {
        no strict 'refs';
        $::PTAGS && $::PTAGS->add_tag($sub, $caller[1], $caller[2]);
        *{"${package}::${sub}"} = subname "${package}::${sub}" => $code;
    }
}

sub document_accessor {
    my ($self, %args) = @_;

    # Don't use() it - this should still work if we don't have
    # Sub::Documentation.
    Sub::Documentation->require;
    return if $@;
    my $package = delete $args{package};
    unless (defined $package) {
        $package = ref $self || $self;
    }
    my $name = delete $args{name};
    $name = [$name] unless ref $name eq 'ARRAY';
    my $belongs_to = delete $args{belongs_to};
    while (my ($type, $documentation) = each %args) {
        Sub::Documentation::add_documentation(
            package       => $package,
            name          => $name,
            glob_type     => 'CODE',
            type          => $type,
            documentation => $documentation,
            ($belongs_to ? (belongs_to => $belongs_to) : ()),
        );
    }
}
1;


__END__
=pod

=head1 NAME

Class::Accessor::Installer - Install an accessor subroutine

=head1 VERSION

version 1.100880

=head1 SYNOPSIS

    package Class::Accessor::Foo;

    use base 'Class::Accessor::Installer';

    sub mk_foo_accessors {
        my ($self, @fields) = @_;
        my $class = ref $self || $self;

        for my $field (@fields) {
            $self->install_accessor(
                sub     => "${field}_foo",
                code    => sub { rand() },
            );
        }

        my $field = '...';
        $self->document_accessor(
            name     => "${field}_foo",
            purpose  => 'Does this, that and the other',
            examples => [
                "my \$result = $class->${field}_foo(\$value)",
                "my \$result = $class->${field}_foo(\$value, \$value2)",
            ],
            belongs_to => 'foo',
        );
    }

=head1 DESCRIPTION

This mixin class provides a method that will install a code reference. There
are other modules that do this, but this one is a bit more specific to the
needs of L<Class::Accessor::Complex> and friends.

It is intended as a mixin, that is, your accessor-generating class should
inherit from this class.

=head1 METHODS

=head2 install_accessor

Takes as arguments a named hash. The following keys are recognized:

=over 4

=item C<package>

The package into which to install the subroutine. If this argument is omitted,
it will inspect C<$self> to determine the package. Class::Accessor::*
accessor generators are typically used like this:

    __PACKAGE__
        ->mk_new
        ->mk_array_accessors(qw(foo bar));

Therefore C<install_accessor()> can determine the right package into which to
install the subroutine.

=item C<name>

The name or names to use for the subroutine. You can either pass a single
string or a reference to an array of strings. Each string is interpreted as a
subroutine name inside the given package, and the code reference is installed
into the appropriate typeglob.

Why would you want to install a subroutine in more than one place inside your
package? For example, L<Class::Accessor::Complex> often creates aliases so the
user can choose the version of the name that reads more naturally.

An example of this usage would be:

        $self->install_accessor(
            name => [ "clear_${field}", "${field}_clear" ],
            code => sub { ... }
        );

=item C<code>

This is the code reference that should be installed.

=back

The installed subroutine is named using L<Sub::Name>, so it shows up with a
meaningful name in stack traces (instead of as C<__ANON__>). However, the
inside the debugger, the subroutine still shows up as C<__ANON__>. You might
therefore want to use the following lines at the beginning of your subroutine:

        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                    if defined &DB::DB && !$Devel::DProf::VERSION;
                ...
        );

Now the subroutine will be named both in a stack trace and inside the
debugger.

=head2 document_accessor

Adds documentation for an accessor - not necessarily one that has been
generated with C<install_accessor()>. See L<Sub::Documentation> for details.

Takes as arguments a named hash. The following keys are recognized:

=over 4

=item C<package>

Like the C<package> argument of C<install_accessor()>.

=item C<name>

The name of the accessor being documented. This can be a string or a reference
to an array of strings, if the same documentation applies to more than one
method. This can occur, for example, when there are aliases for a method such
as C<clear_foo()> and C<foo_clear()>.

=item C<purpose>

A string describing the generated method.

=item C<examples>

An array reference containing one or more examples of using the method. These
will also be used in the generated documentation.

=back

You can pass additional arbitrary key/value pairs; they will be stored as
well. It depends on your documentation tool which keys are useful. For
example, L<Class::Accessor::Complex> generates and
L<Pod::Weaver::Section::CollectWithAutoDoc> supports a C<belongs_to> key that
shows which generated helper method belongs to which main accessor.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Accessor-Installer>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Accessor-Installer/>.

The development version lives at
L<http://github.com/hanekomu/Class-Accessor-Installer/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

  Marcel Gruenauer <marcel@cpan.org>
  Florian Helmberger <florian@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

