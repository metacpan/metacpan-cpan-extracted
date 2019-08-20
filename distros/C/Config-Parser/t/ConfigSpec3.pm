package ConfigSpec3;
use parent 'TestConfig';

sub mangle {
    my $self = shift;
    my $rootdir = $self->get(qw(core root));
    foreach my $kw ($self->names_of('dir')) {
	my $subdir = $self->get('dir', $kw);
	$self->set('dir', $kw, $rootdir . '/' . $subdir);
    }
    return $res;
}

1;
__DATA__
[core]
    root = STRING :mandatory
[dir]    
    temp = STRING
    store = STRING
    diag = STRING
