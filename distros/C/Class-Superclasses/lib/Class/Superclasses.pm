package Class::Superclasses;

use strict;
use warnings;
use List::Util qw(first);
use PPI;

our $VERSION = '0.07';

sub new{
    my ($class,$doc) = @_,
    my $self         = {};
    bless $self,$class;
    
    $self->document($doc);
    
    return $self;
}# new

sub superclasses{
    my ($self) = @_; 
    return wantarray ? @{$self->{super}} : $self->{super};
}# superclasses

sub document{
    my ($self,$doc) = @_;
    if(defined $doc){
        $self->{document} = $doc;
        $self->{super}    = $self->_find_super($doc);
    }
}# document

sub _find_super{
    my ($self,$doc) = @_;
    my $ppi    = PPI::Document->new($doc) or die $!;
    
    my $varref = $ppi->find('PPI::Statement::Variable');
    my @vars   = ();

    if($varref){
        @vars    = $self->_get_isa_values($varref);
    }
    
    my $baseref  = $ppi->find('PPI::Statement::Include');
    my @base     = ();
    my @includes = qw(base parent);

    if($baseref){
        @base = $self->_get_include_values([grep{my $i = $_->module; grep{ $_ eq $i }@includes }@$baseref]);
    }

    my @moose;
    if ( $baseref && first{ $_->module eq 'Moose' or $_->module eq 'Moo' }@$baseref ) {
        my @extends = grep{ $_->schild(0)->content eq "extends" }@{ $ppi->find('PPI::Statement') || [] };

        for my $extend ( @extends ) {
            push @moose, $self->_get_moose_values( $extend );
        }
    }

    return [@vars, @base, @moose];
} # _find_super

sub _get_moose_values{
    my ($self,$elem) = @_;

    my @parents;

    if ( $elem->find_any('PPI::Statement::Expression') ) {
        push @parents, $self->_parse_expression( $elem );
    }
    elsif ( $elem->find_any('PPI::Token::QuoteLike::Words') ) {
        push @parents, $self->_parse_quotelike( $elem );
    }
    elsif ( $elem->find_any( 'PPI::Structure::List' ) ) {
        push @parents, $self->_parse_list( $elem );
    }
    elsif( $elem->find( \&_any_quotes ) ){
        push @parents, $self->_parse_quotes( $elem );
    }

    return @parents;
}# _get_values

sub _get_include_values{
    my ($self,$baseref) = @_;
    my @parents;

    for my $base(@$baseref){
        my @tmp_array;

        if( $base->find_any('PPI::Statement::Expression') ){
            push(@parents,$self->_parse_expression( $base ));
        }
        elsif( $base->find_any('PPI::Token::QuoteLike::Words') ){
            push(@parents,$self->_parse_quotelike( $base ));
        }
        elsif( $base->find( \&_any_quotes ) ){
            push @parents,$self->_parse_quotes( $base );
        }

        @tmp_array = grep{ $_ ne '-norequire' }@tmp_array if $base->module eq 'parent';
        push @parents, @tmp_array;
    }

    return @parents;
}# _get_base_values

sub _any_quotes{
    my ($parent,$elem) = @_;
    
    $parent == $elem->parent and (
        $elem->isa( 'PPI::Token::Quote::Double' ) or
        $elem->isa( 'PPI::Token::Quote::Single' )
    );
}

sub _get_isa_values{
    my ($self,$varref) = @_;
    my @parents;
    for my $variable(@$varref){
        my @children = $variable->children();
        #print Dumper($variable);
        
        if(grep{$_->content() eq '@ISA'}@children){
            if($variable->find_any('PPI::Statement::Expression')){
                push(@parents,$self->_parse_expression($variable));
            }
            elsif($variable->find_any('PPI::Token::QuoteLike::Words')){
                push(@parents,$self->_parse_quotelike($variable));
            }
        }
    }
    return @parents;
}# _get_values

sub _parse_list {
    my ($self, $elem) = @_;

    return $self->_parse_expression( $elem, 'PPI::Structure::List' );
}

sub _parse_expression{
    my ($self, $variable, $token_class) = @_;

    $token_class ||= 'PPI::Statement::Expression';

    my $ref = $variable->find( $token_class );
    my @parents;

    for my $element($ref->[0]->children()){
        if($element->class =~ /^PPI::Token::Quote::/){
            push( @parents,$element->string );
        }
    }

    return @parents;
}# _parse_expression

sub _parse_quotes{
    my ($self,$variable,$type) = @_;
    
    my @parents;
    
    for my $element( $variable->children ){
        my ($type) = ref($element) =~ /PPI::Token::Quote::([^:]+)$/;
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
    my ($left,$right) = split(//,$section_type);
    $right            = $left unless defined $right;
    (my $value        = $words->content()) =~ s~$operator\Q$left\E(.*)\Q$right\E~$1~;
    my @parents       = split(/\s+/,$value);
    return @parents;
}# _parse_quotelike


1;

=pod

=head1 NAME

Class::Superclasses - Find all (direct) superclasses of a class

=head2 DESCRIPTION

C<Class::Superclasses> uses L<PPI> to get the superclasses of a class;

=head1 SYNOPSIS

  use Class::Superclasses;
  
  my $class_file = '/path/to/class_file.pm';
  my $parser = Class::Superclasses->new();
  $parser->document($class_file);
  my @superclasses = $parser->superclasses();
  
  print $_,"\n" for(@superclasses);

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

=cut
