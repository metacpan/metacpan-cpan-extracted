use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use utf8;
use Mojo::Util qw(slurp);
use Data::Dumper;

unshift @INC, sub {
    my(undef, $filename) = @_;
    return () if $filename !~ /V11Parser/;
    if ( my $found = (grep { -e $_ } map { "$_/$filename" } grep { !ref } @INC)[0] ) {
                local $/ = undef;
                open(my $fh, '<', $found) || die("Can't read module file $found\n");
                my $module_text = <$fh>;
                close($fh);

                # define everything in a sub, so Devel::Cover will DTRT
                # NB this introduces no extra linefeeds so D::C's line numbers
                # in reports match the file on disk
                $module_text =~ s/(.*?package\s+\S+)(.*)__END__/$1sub main {$2} main();/s;

                # filehandle on the scalar
                open ($fh, '<', \$module_text);

                # and put it into %INC too so that it looks like we loaded the code
                # from the file directly
                $INC{$filename} = $found;
                return $fh;
     } else {
          return ();
    }
};

use Test::More tests => 9;
use List::Util 'sum';

use_ok 'Business::Payment::SwissESR::V11Parser';

my $p = Business::Payment::SwissESR::V11Parser->new();

is (ref $p,'Business::Payment::SwissESR::V11Parser', 'Instanciation');

my $data3 =  $p->parse(slurp $FindBin::Bin.'/test3.v11');
is (ref $data3, 'ARRAY', 'Parse Output type');
is (scalar @$data3, 155, 'Record Count');
is ($data3->[0]{transactionCost}, '1.75', 'transaction cost test');
is (sum(map { $_->{amount} } @$data3),'15438.7','v11 total');

my $data4 = $p->parse(slurp $FindBin::Bin.'/test4.v11');

is (ref $data4, 'ARRAY', 'Parse Output type');
is (scalar @$data4, 1, 'Record Count');
is ($data4->[0]{submissionReference}, '00020160225007602125808164000000012', 'submission reference');
