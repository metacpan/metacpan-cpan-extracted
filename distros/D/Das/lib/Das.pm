package Das;

BEGIN{
	use Exporter;
	@ISA=qw(Exporter);
	@EXPORT=qw(&check_IP &checkEmailId)
}
$DefaultClass = 'Das';
sub new{
	my ($class,@initializer) = @_;
	my $self = {};
	
	bless $self,ref $class || $class || $DefaultClass;
	return $self;
}
sub check_IP {
	my ($self,$ip) = @_;
	chomp($ip);
	$self->{ip} = $ip;
	if(($ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) && (( $1<255 && $2<255 && $3<255 && $4<255 ))){
		return 1;
	}else {
		return 0;
	}
}
sub checkEmailId {
	my ($self,$email) = @_;
	chomp($email);
	$self->{email}=$email;
	if($email =~ /^[^\_|\.|\-](\w|\.)+\@(\w+\.)+\w+$/){
		return 1;
	}else {
		return 0;
	}
}
1;
