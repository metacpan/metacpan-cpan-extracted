package App::CSE::File::ApplicationXPerl;
$App::CSE::File::ApplicationXPerl::VERSION = '0.016';
use Moose;
extends qw/App::CSE::File/;

use PPI;
# use PPI::Dumper;

has 'ppi' => ( is => 'ro', isa => 'Maybe[PPI::Document]', lazy_build => 1);

sub _build_ppi{
    my ($self) = @_;
    my $doc = PPI::Document->new($self->file_path());
    # my $dumper = PPI::Dumper->new( $doc );
    # warn($dumper->string());
    return $doc;
}

sub _build_call{
    my ($self) = @_;
    unless( $self->ppi() ){ return []; }

    my @calls = ();
    $self->ppi->find(sub{
	if( $_[1]->isa('PPI::Token::Word') && (  $_[1]->method_call()
	    || _is_function_call($_[1]) ) ){
	    push @calls, $_[1]->literal();
	}
    });

    return \@calls;
}

# Dirty implementation of 'is a PPI token a function call'
# Until PPI does it the right way (see TODO in PPI::Token::Word).
sub _is_function_call{
    my ($ppi_token) = @_;
    my $snext = $ppi_token->snext_sibling();
    return 0 unless $snext;
    return $snext->isa('PPI::Structure::List');
}

sub _build_decl{
  my ($self) = @_;

  unless( $self->ppi() ){ return []; }

  my @declarations = ();

  ## Find and push all subs declarations
  $self->ppi->find(sub{
                      $_[1]->isa('PPI::Statement::Sub') and $_[1]->name and !$_[1]->reserved()
                        and push @declarations , $_[1]->name();
                   });

  ## Find and push all package declarations
  $self->ppi->find(sub{ $_[1]->isa('PPI::Statement::Package')
                          and $_[1]->namespace()
                            and
                              push @declarations , $_[1]->namespace()
                            }
                  );
  return \@declarations;
}

__PACKAGE__->meta->make_immutable();
