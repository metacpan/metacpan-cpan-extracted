package Catalyst::Plugin::AutoCRUD::View::TT;
{
  $Catalyst::Plugin::AutoCRUD::View::TT::VERSION = '2.143070';
}

use strict;
use warnings;

use base 'Catalyst::View::TT';
use File::Basename;
use MRO::Compat;

# the templates are squirreled away in ../templates
(my $pkg_path = __PACKAGE__) =~ s{::}{/}g;
my (undef, $directory, undef) = fileparse(
    $INC{ $pkg_path .'.pm' }
);

__PACKAGE__->config(
    INCLUDE_PATH => "$directory../templates",
    CATALYST_VAR => 'c',
    WRAPPER => 'wrapper.tt',
    ENCODING => 'utf-8',
    PRE_CHOMP => 1,
    render_die => 1,
);

sub process {
    my ($self, $c) = (shift, $_[0]);

    # this is done to cope with users of RenderView who have not set
    # default_view, meaning $c->view ends here by mistake

    if (!exists $c->stash->{current_view}) {
        my @views = grep {$_ !~ m/^AutoCRUD::/} $c->views;
        scalar @views || die "View::AutoCRUD::TT called, but not by CPAC.\n";
        $c->forward( $c->view( $views[0] ) );
    }
    else {
        return $self->next::method(@_);
    }
}

1;
__END__
