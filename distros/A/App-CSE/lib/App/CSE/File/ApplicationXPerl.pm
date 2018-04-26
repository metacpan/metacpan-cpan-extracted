package App::CSE::File::ApplicationXPerl;
$App::CSE::File::ApplicationXPerl::VERSION = '0.014';
use Moose;
extends qw/App::CSE::File/;

use PPI;

has 'ppi' => ( is => 'ro', isa => 'Maybe[PPI::Document]', lazy_build => 1);

sub _build_ppi{
  my ($self) = @_;
  return PPI::Document->new($self->file_path());
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
