package ConfigSpec;
use parent 'TestConfig';

sub _check_abs_name {
    my ($self, $valref, $prev_value, $locus) = @_;
    unless ($$valref =~ m{^/}) {
	$self->error("not an absolute pathname", locus => $locus);
	return 0;
    }
    1;
}
	
1;
__DATA__
[core]   
    base = STRING :mandatory null
    number = NUMBER :array
    size = STRING :re='\d+(?:(?i) *[kmg])'
    enable = BOOL
[load]
    file = STRING :check=_check_abs_name :mandatory
    ANY = STRING
  
