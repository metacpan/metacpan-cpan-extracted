package Class::Superclasses;

use strict;
use warnings;

use List::Util qw(first);
use PPI;

our $VERSION = '0.08';

sub new{
    my ($class,$doc) = @_,
    my $self         = {};

    bless $self,$class;
    
    $self->document($doc);
    
    return $self;
}

sub superclasses{
    my ($self) = @_; 
    return wantarray ? @{$self->{super}} : $self->{super};
}

sub document{
    my ($self,$doc) = @_;

    if(defined $doc){
        $self->{document} = $doc;
        $self->{super}    = $self->_find_super($doc);
    }

    return $self;
}

sub _find_super{
    my ($self,$doc) = @_;

    my $ppi    = PPI::Document->new($doc) or die $!;
    my $varref = $ppi->find('PPI::Statement::Variable');
    my @vars   = ();

    if($varref){
        @vars    = $self->_get_isa_values($varref);
    }
    
    my $baseref  = $ppi->find('PPI::Statement::Include') || [];
    my @includes = qw(base parent);
    my @base     = $self->_get_include_values([grep{my $i = $_->module; grep{ $_ eq $i }@includes }@$baseref]);

    my @moose;
    my @moose_like_modules = qw(Moose Moo Mouse Mo);
    my $is_moose;

    for my $base_class ( @{$baseref} ) {
        if ( first{ $base_class->module eq $_ }@moose_like_modules ) {

            for my $stmt ( @{ $ppi->find('PPI::Statement') } ) {
                push @moose, $self->_get_moose_values( $stmt );
            }
        }
    }

    return [@vars, @base, @moose];
}

sub _get_moose_values{
    my ($self,$elem) = @_;

    my @parents;

    return if $elem->schild(0)->content ne 'extends';

    if ( $elem->find_any('PPI::Statement::Expression') ) {
        push @parents, $self->_parse_expression( $elem );
    }
    elsif ( $elem->find_any('PPI::Token::QuoteLike::Words') ) {
        push @parents, $self->_parse_quotelike( $elem );
    }
    elsif( $elem->find( \&_any_quotes ) ){
        push @parents, $self->_parse_quotes( $elem );
    }

    return @parents;
}

sub _get_include_values{
    my ($self, $baseref) = @_;
    my @parents;

    BASE:
    for my $base( @{$baseref} ){
        my @tmp_array;

        if( $base->find_any('PPI::Statement::Expression') ){
            push @tmp_array, $self->_parse_expression( $base );
        }
        elsif( $base->find_any('PPI::Token::QuoteLike::Words') ){
            push @tmp_array, $self->_parse_quotelike( $base );
        }
        elsif( $base->find( \&_any_quotes ) ){
            push @tmp_array, $self->_parse_quotes( $base );
        }

        if ( $base->module eq 'parent' ) {
            @tmp_array = grep{ $_ ne '-norequire' }@tmp_array;
        }

        push @parents, @tmp_array;
    }

    return @parents;
}

sub _any_quotes{
    my ($parent,$elem) = @_;

    $parent eq $elem->parent and (
        $elem->isa( 'PPI::Token::Quote::Double' ) or
        $elem->isa( 'PPI::Token::Quote::Single' )
    );
}

sub _get_isa_values{
    my ($self,$varref) = @_;
    my @parents;

    for my $variable ( @{ $varref || [] } ) {
        my @children = $variable->children();
        
        if( grep{$_->content eq '@ISA'}@children ) {
            if( $variable->find_any('PPI::Token::QuoteLike::Words') ) {
                push @parents, $self->_parse_quotelike($variable);
            }
            elsif( $variable->find_any('PPI::Statement::Expression') ) {
                push @parents, $self->_parse_expression($variable);
            }
        }
    }

    return @parents;
}

sub _parse_expression {
    my ($self, $variable) = @_;

    my $ref = $variable->find( 'PPI::Statement::Expression' );
    my @parents;

    for my $expression ( @{$ref} ) {
        for my $element( $expression->children ){
            if( $element->class =~ /^PPI::Token::Quote::/ ) {
                push @parents, $element->string;
            }
        }
    }

    return @parents;
}

sub _parse_quotes{
    my ($self,$variable,$type) = @_;
    
    my @parents;
    
    for my $element( $variable->children ){
        my ($type) = $element->class =~ /PPI::Token::Quote::([^:]+)$/;

        next unless $type;

        my $value  = $element->string;
        push @parents, $value;
    }

    return @parents;
}

sub _parse_quotelike{
    my ($self,$variable) = @_;

    my $words         = ($variable->find('PPI::Token::QuoteLike::Words'))[0]->[0];
    my $operator      = $words->{operator};
    my $section_type  = $words->{sections}->[0]->{type};
    my ($left,$right) = split //, $section_type;
    (my $value        = $words->content) =~ s~$operator\Q$left\E(.*)\Q$right\E~$1~;
    my @parents       = split /\s+/, $value;

    return @parents;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Superclasses

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  use Class::Superclasses;
  
  my $class_file = '/path/to/class_file.pm';
  my $parser = Class::Superclasses->new();
  $parser->document($class_file);
  my @superclasses = $parser->superclasses();
  
  print $_,"\n" for(@superclasses);

=head1 NAME

Class::Superclasses - Find all (direct) superclasses of a class

=head2 DESCRIPTION

C<Class::Superclasses> uses L<PPI> to get the superclasses of a class;

=head1 METHODS

=head2 new

creates a new object of C<Class::Superclasses>. 

  my $parser = Class::Superclasses->new();
  # or
  my $parser = Class::Superclasses->new($filename);

=head2 superclasses

returns in list context an array of all superclasses of the Perl class, in
scalar context it returns an arrayref.

  my $arrayref = $parser->superclasses();
  my @array = $parser->superclasses();

=head2 document

tells C<Class::Superclasses> which Perl class should be analyzed.

  $parser->document($filename);

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
