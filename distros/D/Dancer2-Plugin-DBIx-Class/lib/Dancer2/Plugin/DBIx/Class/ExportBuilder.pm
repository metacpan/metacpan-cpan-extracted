package Dancer2::Plugin::DBIx::Class::ExportBuilder;
use Modern::Perl;
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY
use Carp;
use Class::C3::Componentised;
use curry 2.000001;
use Moo;

has schema_class => (is => 'ro', required => 1);

has dsn => (is => 'ro', required => 1);

has user => (is => 'ro');

has password => (is => 'ro');

has schema => (
   is      => 'lazy',
   builder => sub {
      my ($self) = @_;
      $self->_ensure_schema_class_loaded->connect( $self->dsn, $self->user, $self->password );
   },
);

has export_prefix => (is => 'ro');

sub _maybe_prefix_method {
   my ( $self, $method ) = @_;
   return $method unless $self->export_prefix;
   return join( '_', $self->export_prefix, $method );
}

sub _rs_name_methods {
   my ($self) = @_;
   my $class = $self->_ensure_schema_class_loaded;
   return () unless $class->can('resultset_name_methods');
   sort keys %{ $class->resultset_name_methods };
}

sub _ensure_schema_class_loaded {
   croak 'No schema class defined' if !$_[0]->schema_class;
   eval { Class::C3::Componentised->ensure_class_loaded( $_[0]->schema_class ); 1; }
       or croak 'Schema class ' . $_[0]->schema_class . ' unable to load';
   return $_[0]->schema_class;
}

sub exports {
   my ($self)  = @_;
   my $schema = $self->schema;
   my %kw;
## no critic qw(Variables::ProhibitPackageVars)
   $kw{$_} = $schema->$curry::curry($_) for $self->_rs_name_methods;
   return map {
      $self->_maybe_prefix_method($_)
        => do {
             my $code = $kw{$_};
             sub { shift; &$code }
           }
    } sort keys %kw;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::DBIx::Class::ExportBuilder

=head1 VERSION

version 1.1001

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
