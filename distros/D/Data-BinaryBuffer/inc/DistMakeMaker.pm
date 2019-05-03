package inc::DistMakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my $self = shift;
    my $full_tmpl = super();
    my $configure_tmpl = $self->_configure_tmpl();

    $full_tmpl =~ s/(^WriteMakefile\(.+?\);\s*$)/$configure_tmpl\n$1/ms;
    return $full_tmpl;
};

sub _configure_tmpl {
    my $self = shift;
    my $tmpl = <<'TEMPLATE';
use Config ();
use Text::ParseWords 'shellwords';
use FindBin;
use lib $FindBin::Bin;
use inc::CConf;

$WriteMakefileArgs{CONFIGURE} = sub {
    my %args;

    my $c = inc::CConf->new();

    $c->add_header_search_path("$FindBin::Bin/databb-boost");

    $c->need_cplusplus;

    %args = $c->makemaker_args;

    $args{TYPEMAPS} = ['perlobject.map'];

    return \%args;
};
TEMPLATE
    return $tmpl;
}

__PACKAGE__->meta->make_immutable;
