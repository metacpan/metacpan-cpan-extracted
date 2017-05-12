package App::Unix::RPasswd::SaltedPasswd;
# This is an internal module of App::Unix::RPasswd

use feature ':5.10';
use Moo;
use Crypt::PasswdMD5 ('unix_md5_crypt');
use List::MoreUtils  ('zip');

our $VERSION = '0.53';
our $AUTHOR  = 'Claudio Ramirez <nxadm@cpan.org>';

has 'salt' => (
    is       => 'ro',
    #isa      => 'Str',
    required => 1,
);

has 'minalpha' => ( # Minimum number of alpha character required
    is       => 'ro',
    #isa      => 'Int',
    default => sub { 2 },   # 2 is the default in Solaris 11
    required => 0,
);

sub generate {
    my ($self, $base_password)   = @_;
    
    # Create an encoded string
    my $passwd = $self->_encode_string(
        unix_md5_crypt( $base_password, $self->salt ) );
    
    # If necessary convert it to respect the minalpha constraint
    $passwd = $self->_minalpha_conv($passwd);
    return $passwd;
}

sub _encode_string {
    my ( $self, $opasswd ) = @_;
    $opasswd =~ tr/ /./;
    $opasswd =~ s/\$//g;
    my @array1  = split( //, $opasswd );
    my @array2  = reverse @array1;
    my @array3  = zip( @array2, @array1 );
    my $npasswd = join( '', @array3 );
    my $offset  = ( length $npasswd ) / 2 + 3;
    my $passwd  = substr( $npasswd, $offset, 12 ); # The password is 12 chars long
    return reverse $passwd;
}

sub _minalpha_conv {
    my ( $self, $opasswd ) = @_;
    my $passwd;
    my $first8_chars = substr($opasswd, 0, 8);
    if ($first8_chars !~ /[0-9]/) {
        my $ascii_value = ord(substr($first8_chars, 0, 1));
        my $sum;
        do {
            $sum = 0;
            my @digits = split(//,$ascii_value);
            for my $d (@digits) { $sum += $d; }
            $ascii_value = $sum;
        } while (length $sum != 1);
        $passwd = $sum . substr($opasswd, 1);
    }
    else { $passwd = $opasswd; }
    return $passwd;
   }

1;

# Additional properties of generated passwords
#MINDIFF=3      Minimum differences required between an old and a new password => OK (statically)
#MINALPHA=2     Minimum number of alpha character required => Done

# MAYBE TODO: make passwords suitable for new default configurations (e.g. Solaris 11)
#MINNONALPHA=1  Minimum number of non-alpha (including numeric and special) required
#MINUPPER=0     Minimum number of upper case letters tequired
#MINLOWER=0     Minimum number of lower case letters required
#MAXREPEATS=0   Maximum number of allowable consecutive repeating characters
#MINSPECIAL=0   Minimum number of special (non-alpha and non-digit) characters required
#MINDIGIT=0     Minimum number of digits required
#WHITESPACE=YES Determine if white space characters are allowed in passwords
