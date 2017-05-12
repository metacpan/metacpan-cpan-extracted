package My::Thingy;

use strict;

use Apache2::DirBasedHandler::TT
our @ISA = qw(Apache2::DirBasedHandler::TT);

use Apache2::Const -compile => qw(:common);

sub root_index {
    my $self = shift;
    my ($r,$uri_args,$args) = @_;

    if (@$uri_args) {
        return Apache2::Const::NOT_FOUND;
    }
    $$args{'vars'}{'blurb'} = qq[this is the index];

    return $self->process_template(
        $r,
        $$args{'tt'},
        $$args{'vars'},
        qq[blurb.tmpl],
        qq[text/plain; charset=utf-8],
    );
}

sub super_page {
    my $self = shift;
    my ($r,$uri_args,$args) = @_;
    $$args{'vars'}{'blurb'} = qq[this is \$location/super and all it's contents];

    return $self->process_template(
        $r,
        $$args{'tt'},
        $$args{'vars'},
        qq[blurb.tmpl],
        qq[text/plain; charset=utf-8],
    );
}

sub super_dooper_page {
    my $self = shift;
    my ($r,$uri_args,$args) = @_;
    $$args{'vars'}{'blurb'} = qq[this is \$location/super/dooper and all it's contents];

    return $self->process_template(
        $r,
        $$args{'tt'},
        $$args{'vars'},
        qq[blurb.tmpl],
        qq[text/plain; charset=utf-8],
    );
}

1;
