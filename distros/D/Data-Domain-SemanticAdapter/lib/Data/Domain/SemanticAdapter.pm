use 5.008;
use strict;
use warnings;

package Data::Domain::SemanticAdapter;
our $VERSION = '1.100840';
# ABSTRACT: Adapter for Data::Semantic objects
use Carp;
use UNIVERSAL::require;
use parent qw(
  Data::Domain
  Data::Inherited
  Class::Accessor::Complex
);
__PACKAGE__->mk_scalar_accessors(qw(adaptee));

# sub adaptee() to be defined in subclasses
use constant OPTIONS => ();

sub new {
    my $class   = shift;
    my $self    = bless {}, $class;
    my @options = (qw/-not_in/, $self->every_list('OPTIONS'));
    my $parsed  = Data::Domain::_parse_args(\@_, \@options);
    while (my ($key, $value) = each %{ $parsed || {} }) {
        $self->{$key} = $value;
    }
    if ($self->{-not_in}) {
        @{ $self->{-not_in} || [] } > 0
          or croak "-not_in : needs an arrayref of values";
    }
    my $semantic_class_name = $self->semantic_class_name;
    $semantic_class_name->require;
    $self->adaptee($semantic_class_name->new($self->semantic_args));
    $self;
}

# Default; subclasses can redefine this. But it makes sense to keep the
# Data::Domain::* and Data::Semantic::* namespaces in sync.
sub semantic_class_name {
    my $self = shift;
    (my $semantic_class_name = ref $self) =~
      s/^Data::Domain::/Data::Semantic::/;
    $semantic_class_name;
}

# Turn the options accepted because of OPTIONS() into args to be passed to the
# adaptee constructor. Here we provide a sensibe default.
sub semantic_args {
    my $self = shift;
    my %args;
    for my $option ($self->OPTIONS) {
        (my $semantic_key = $option) =~ s/^-//;
        $args{$semantic_key} = $self->{$option} if defined $self->{$option};
    }
    %args;
}

sub _inspect {
    my ($self, $data) = @_;
    $self->adaptee->is_valid($data)
      or return $self->msg(INVALID => $data);
    if (defined $self->{-not_in}) {
        grep { $data eq $_ } @{ $self->{-not_in} }
          and return $self->msg(EXCLUSION_SET => $data);
    }
}

# mirror the Data::Semantic::Name namespace classes
sub install_shortcuts {
    my %map      = @_;
    my $call_pkg = (caller)[0];
    while (my ($domain, $class) = each %map) {
        no strict 'refs';
        my $domain_class_name = "Data::Domain::$class";
        $domain_class_name->require;
        *{"${call_pkg}::${domain}"} = sub { $domain_class_name->new(@_) };
    }
}
1;


__END__
=pod

=head1 NAME

Data::Domain::SemanticAdapter - Adapter for Data::Semantic objects

=head1 VERSION

version 1.100840

=head1 DESCRIPTION

This class is an adapter (wrapper) that turns L<Data::Semantic> objects into
L<Data::Domain> objects.

It, and therefore all the subclasses, support a C<-not_in> options. If given,
the data must be different from all values in the exclusion set, supplied
as an arrayref.

=head1 METHODS

=head2 semantic_class_name

Returns the corresponding semantic class name. This method provides a default
mapping, the idea of which is to mirror the layout of the Data::Semantic class
tree. If you have a different mapping, override this method in a subclass.

So in the Data::Domain::URI::http class, it will return
C<Data::Semantic::URI::http>.

=head2 adaptee

Takes the results of C<semantic_class_name()> and C<semantic_args()>, loads
the semantic data class and returns a semantic data object with the given args
passed to its constructor.

=head2 semantic_args

Turns the object's options, specified via C<OPTIONS()>, into arguments to be
passed to the semantic data object's constructor. Returns a hash.

=head2 _inspect

Inspects the data using the C<adaptee()>. See L<Data::Domain> for more
information. Respects the C<-not_in> option and returns a C<EXCLUSION_SET>
message, if appropriate. If the adaptee() says that the data is not valid
under the given options, an C<INVALID> message is returned.

=head2 install_shortcuts

This is a convenience function (not method) that installs shortcuts into the
calling package. It expects a mapping hash whose keys are the shortcuts to be
created and whose values are the package names relative to C<Data::Domain::>.
See L<Data::Domain>, section I<Shortcut functions for domain constructors>, for
more information on shortcuts.

Here is an example from L<Data::Domain::Net>:

    our %map = (
        IPv4 => 'Net::IPAddress::IPv4',
        IPv6 => 'Net::IPAddress::IPv6',
    );

    Data::Domain::SemanticAdapter::install_shortcuts(%map);

This installs two functions, C<IPv4()> and C<IPv6()>, into Data::Domain::Net.
Now code that wants to use network-based domain objects can just say:

    use Data::Domain::Net ':all';

    my $domain = IPv4(-not_in => [ ... ]);
    $domain->inspect(...);

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Domain-SemanticAdapter>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Domain-SemanticAdapter/>.

The development version lives at
L<http://github.com/hanekomu/Data-Domain-SemanticAdapter/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

