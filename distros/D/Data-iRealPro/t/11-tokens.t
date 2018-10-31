#!perl -T

use Test::More tests => 5;

BEGIN {
    use_ok( 'Data::iRealPro::URI' );
}

my $u = Data::iRealPro::URI->new;
ok( $u, "Create URI object" );

my $data = <<EOD;
<a href="irealb://You're%20Still%20The%20One%3DTwain%20Shania%3D%3DRock%20Ballad%3DC%3D%3D1r34LbKcu7L%23F/D4DLZD%7D%20AZLGZL%23F/DZLAD*%7B%0A%7D%20AZLGZL%23F/%0A%7CDLZ4Ti*%7BDZLAZLZSDLGZLDB*%7B%0A%5D%20AZLALZGZLDZLAZLAZLGZLZE-LAZLGZ%23F/DZALZN1%5D%20%3EadoC%20la%20.S.%3CD%20A2N%7CQyXQyX%7D%20G%0A%5BQDLZLGZLLZGLZfA%20Z%20%3D%3D155%3D0">You're Still The One</a>
EOD

$u->parse($data);
ok( $u->{playlist}, "Got playlist" );
my $pl = $u->{playlist};
is( scalar(@{$pl->{songs}}), 1, "Got one song" );
my $song = $pl->{songs}->[0];
$song->tokenize;

my $dd = <<EOD;
{*iT44D |D/F# |G |A }
{*AD |D/F# |G |A }
|D |D/F# |G |A |SD |G |A |A |D |G |A |A ]
{*BD |G |E- |A |D |G |A |N1G }      |N2A <D.S. al Coda> ]
[QD |D/F# |G |fA Z 
EOD
chomp($dd);

my $exp =
  {
   a2		   => '',
   actual_key	   => '',
   actual_repeats  => 0,
   actual_style	   => '',
   actual_tempo	   => 155,
   composer	   => "Twain Shania",
   data		   => $dd,
   debug	   => undef,
   key		   => "C",
   style	   => "Rock Ballad",
   title	   => "You're Still The One",
   transpose	   => 0,
   variant	   => "irealpro",
   tokens => [
    'start repeat',
    'mark i',
    'time 4/4',
    'chord D',
    'advance 1',
    'bar',
    'chord D/F#',
    'advance 1',
    'bar',
    'chord G',
    'advance 1',
    'bar',
    'chord A',
    'advance 1',
    'end repeat',
    'start repeat',
    'mark A',
    'chord D',
    'advance 1',
    'bar',
    'chord D/F#',
    'advance 1',
    'bar',
    'chord G',
    'advance 1',
    'bar',
    'chord A',
    'advance 1',
    'end repeat',
    'bar',
    'chord D',
    'advance 1',
    'bar',
    'chord D/F#',
    'advance 1',
    'bar',
    'chord G',
    'advance 1',
    'bar',
    'chord A',
    'advance 1',
    'bar',
    'segno',
    'chord D',
    'advance 1',
    'bar',
    'chord G',
    'advance 1',
    'bar',
    'chord A',
    'advance 1',
    'bar',
    'chord A',
    'advance 1',
    'bar',
    'chord D',
    'advance 1',
    'bar',
    'chord G',
    'advance 1',
    'bar',
    'chord A',
    'advance 1',
    'bar',
    'chord A',
    'advance 1',
    'end section',
    'start repeat',
    'mark B',
    'chord D',
    'advance 1',
    'bar',
    'chord G',
    'advance 1',
    'bar',
    'chord E-',
    'advance 1',
    'bar',
    'chord A',
    'advance 1',
    'bar',
    'chord D',
    'advance 1',
    'bar',
    'chord G',
    'advance 1',
    'bar',
    'chord A',
    'advance 1',
    'bar',
    'alternative 1',
    'chord G',
    'advance 1',
    'end repeat',
    'hspace 6',
    'bar',
    'alternative 2',
    'chord A',
    'advance 1',
    'text 0 D.S. al Coda',
    'advance 1',
    'end section',
    'start section',
    'coda',
    'chord D',
    'advance 1',
    'bar',
    'chord D/F#',
    'advance 1',
    'bar',
    'chord G',
    'advance 1',
    'bar',
    'fermata',
    'chord A',
    'advance 1',
    'end',
    'advance 1'
	     ] };

is_deeply( $song, $exp, "Tokenized" );
