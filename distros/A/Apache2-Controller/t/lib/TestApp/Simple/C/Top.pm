package TestApp::Simple::C::Top;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( Apache2::Controller Apache2::Request );

use Readonly;
use Apache2::Const -compile => qw(OK);
use Log::Log4perl qw(:easy);

sub allowed_methods {qw( default pie )}

sub default {
    my ($self) = @_;
    $self->content_type('text/plain');
    $self->print("Top level handler.\n");
    return Apache2::Const::OK;
}

# test path_args:
sub pie {
    my ($self) = @_;
    my $path_args = $self->{path_args};
    my $flavor = shift @{$path_args};
    DEBUG("pie flavor is '$flavor'");
    die "no more pie" if !$flavor;
    $self->print("Simple as $flavor pie.\n");
    return Apache2::Const::OK;
}


1;
