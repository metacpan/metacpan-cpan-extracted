package Business::Payment::SwissESR::V11Parser;

=head1 NAME

Business::Payment::SwissESR::V11Parser - Class for parsing v11 records

=head1 SYNOPSYS

 use Business::Payment::SwissESR::V11Parser;
 my $parser = Business::Payment::SwissESR::V11Parser->new();
 my $records = $parser->parse($data);
 for my $rec (@$records){
    warn Dumper $rec;
 }

=head1 DESCRIPTION

When issuing ESR payment slips to your customers, you can get payment data from swisspost in
the form of so called v11 files. They contain information about the paiments received. This
class transforms this information into easily accessible data.

See records L<https://www.postfinance.ch/content/dam/pf/de/doc/consult/manual/dldata/efin_recdescr_man_de.pdf>
for details (2.1 Gutschriftrecord Typ 3 and 2.3 Gutschriftrecord Typ 4).

=head1 METHODS

=head2 $p->parse($string)

parses v11 encoded data and returns an array of hashes where each hash represents a payment.

typ3

      [ ...
          {
            'status' => 'reject',
            'microfilmReference' => '000010086',
            'transferDate' => '2012-09-26',
            'payDate' => '2012-09-25',
            'paymentLocation' => 'postoffice counter',
            'creditDate' => '2012-09-27',
            'submissionReference' => '5100  0100',
            'paymentType' => 'payment',
            'transactionCost' => '0.9',
            'paymentSlip' => 'ESR+',
            'amount' => '20',
            'referenceNumber' => '326015262012',
            'reseved' => '000000000',
            'accontNumber' => '01-17546-3'
          },
          {
            'status' => 'ok',
            'microfilmReference' => '004570001',
            'transferDate' => '2012-09-26',
            'payDate' => '2012-09-26',
            'paymentLocation' => 'online',
            'creditDate' => '2012-09-27',
            'submissionReference' => '0040  0400',
            'paymentType' => 'payment',
            'transactionCost' => '0',
            'paymentSlip' => 'ESR',
            'amount' => '40',
            'referenceNumber' => '326015852012',
            'reseved' => '000000000',
            'accontNumber' => '01-17546-3'
          },
       ... ]

typ4
    [ ...
        {
        'paymentType' => 'payment',
          'currency2' => 'CHF',
          'payDate' => '2016-02-25',
          'amount' => '64',
          'paymentSlip' => 'ESR CHF',
          'microfilmReference' => '-',
          'currency' => 'CHF',
          'status' => 'ok',
          'accontNumber' => '01-89079-7',
          'transferDate' => '2016-02-25',
          'deliveryType' => 'original',
          'paymentLocation' => 'eurosic',
          'paymentSource' => 'normal',
          'creditDate' => '2016-02-26',
          'submissionReference' => '00020160225007602125808164000000012',
          'transactionCost' => '0',
          'referenceNumber' => '9320'
        }
    ]

=cut

use Mojo::Base -base;

use vars qw($VERSION);
our $VERSION = '0.13.3';

# all the magic of this parser is in setting up the right infrastructure
# so that we can blaze through the file with just a few lines of code
# later on.

my $date = {
    w => 6,
    rx => qr/(..)(..)(..)/,
    su => sub {
        return ((2000+$_[0])."-$_[1]-$_[2]");
    }
};
my $date4 = {
    w => 8,
    rx => qr/(....)(..)(..)/,
    su => sub {
        return "$_[0]-$_[1]-$_[2]";
    }
};

my %src = (
  '0' => 'online',
  '1' => 'postoffice counter',
  '2' => 'cash on delivery'
);

my %type = (
   '2' => 'payment',
   '5' => 'refund',
   '8' => 'correction'
);

# the v11 format is a fixed with data format. in the format structure
# we have the width (w) of each column as well as an optional regular expression
my $GSR = {
    typ3 => [
        paymentSlip => {
            w => 1,
            su => sub {
                return $_[0] ? 'ESR+' : 'ESR';
            }
        },
        paymentLocation => {
            w => 1,
            su => sub {
                return $src{$_[0]} || $_[0];
            }
        },
        paymentType => {
            w => 1,
            su => sub {
                return $type{$_[0]} || $_[0];
            }
        },
        accontNumber => {
            w => 9,
            rx => qr/(..)0*(.+)(.)/,
            su => sub {
                return "$_[0]-$_[1]-$_[2]";
            }
        },
        referenceNumber => {
            w => 27,
            rx => qr/(.+)./,
            su => sub {
                my $ret = shift;
                $ret =~ s/^0+//;
                return $ret;
            }
        },
        amount => {
            w => 10,
            su => sub {
                return int($_[0]) / 100;
            }
        },
        submissionReference => 10,
        payDate => $date,
        transferDate => $date,
        creditDate => $date,
        microfilmReference => 9,
        status => {
            w => 1,
            su => sub {
                return $_[0] ? "reject" : "ok"
            }
        },
        reseved => 9,
        transactionCost => {
            w => 4,
            su => sub {
                return int($_[0]) / 100;
            }
        }
    ],
    typ4 => [
        paymentSlip => {
            w => 1,
            su => sub {
                return [
                    'ESR CHF',
                    'ESR+ CHF',
                    'ESR EUR',
                    'ESR+ EUR'
                ]->[$_[0]];
            }
        },
        paymentSource => {
            w => 1,
            su => sub {
                return [ undef,'normal','nachnahme','ownaccount']->[$_[0]] // 'Unknown Source '.$_[0];
            }
        },
        paymentType => {
            w => 1,
            su => sub {
                return [undef,'payment','refund','correction']->[$_[0]] // 'Unknown Type '.$_[0];
            }
        },
        paymentLocation => {
            w => 2,
            su => sub {
                return {
                    '01' => 'postoffice counter',
                    '02' => 'zag/dag',
                    '03' => 'online',
                    '04' => 'eurosic'
                }->{$_[0]} // 'Unknown Location '.$_[0];
            }
        },
        deliveryType => {
            w => 1,
            su => sub {
                return [undef,'original','reko','test']->[$_[0]] // 'Unkown Delivery '.$_[0];
            }
        },
        accontNumber => {
            w => 9,
            rx => qr/(..)0*(.+)(.)/,
            su => sub {
                return "$_[0]-$_[1]-$_[2]";
            }
        },
        referenceNumber => {
            w => 27,
            rx => qr/^0+(.+)./,
        },
        currency => 3,
        amount => {
            w => 12,
            su => sub {
                return int($_[0]) / 100;
            }
        },
        submissionReference => 35,
        payDate => $date4,
        transferDate => $date4,
        creditDate => $date4,
        status => {
            w => 1,
            su => sub {
                return $_[0] ? "reject" : "ok"
            }
        },
        currency2 => 3,
        transactionCost => {
            w => 6,
            su => sub {
                return int($_[0]) / 100;
            }
        }
    ]
};
my %parser;

for my $type (keys %$GSR){
    my @keys;
    my $parser = '^';
    my %proc;

    while (my $key = shift @{$GSR->{$type}}){
        my $val = shift @{$GSR->{$type}};
        my $w = $val;
       my $rx = qr/(.*)/;
       my $su = sub { return shift };
       if (ref $val){
          $w = $val->{w} || die "$key -> w - width property is mandatory";
          $su = $val->{su} // $su;
          $rx = $val->{rx} // $rx;
       }
       push @keys, $key;
       $parser .= "(.{$w})";
       $proc{$key} = {
           rx => $rx,
           su => $su
       }
    }
    $parser .= '$';
    $parser{$type} = {
        rx => $parser,
        proc => \%proc,
        keys => \@keys
    };
}

sub parse {
    my $self = shift;
    my @data = split /[\r?\n]/, shift;
    my @all;
    for my $line (@data){
        $line =~ s/\s+$//;
        for my $type (keys %parser){
            my %d;
            my $parse = $parser{$type}{rx};
            my @keys = @{$parser{$type}{keys}};
            @d{@keys} = $line =~ /$parse/;
            $d{microfilmReference} //= '-';
            next if not defined $d{transactionCost};
            for my $key (keys %{$parser{$type}{proc}}){
                if (my $su =  $parser{$type}{proc}{$key}{su} ){
                    $d{$key} = $su->( $d{$key} =~ $parser{$type}{proc}{$key}{rx} );
                }
            }
            push @all,\%d;
            last;
        }
    }
    return \@all;
}


1;

__END__

=back

=head1 COPYRIGHT

Copyright (c) 2014 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2014-06-23 to 0.6 initial version

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et
