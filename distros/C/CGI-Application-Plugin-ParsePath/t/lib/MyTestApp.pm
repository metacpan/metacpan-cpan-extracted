package MyTestApp;
use base 'CGI::Application';
use CGI::Application::Plugin::ParsePath;
use Data::Dumper;
use Storable qw/freeze/;

sub setup {
    my $self = shift;
    $self->start_mode('recent');
    $self->run_modes([qw/posts recent edit by_date/]);
}

sub _dump_vars {
    my $self = shift;
    my %vars = $self->query->Vars;
    $self->header_type('none');
    return freeze(\%vars);
}


sub posts {
    $_[0]->_dump_vars;
}

sub recent {
    $_[0]->_dump_vars;
}

sub edit {
    $_[0]->_dump_vars;
}

sub by_date {
    $_[0]->_dump_vars;
}

1;
