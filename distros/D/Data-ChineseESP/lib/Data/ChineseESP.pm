package Data::ChineseESP;

use 5.006;
use strict;
use warnings;

=head1 NAME

Data::ChineseESP - Chinese big email service providers

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Dump Chinese big email service providers, for antispam purpose etc.

If you have found a new one, please contact me to update the list.


    use Data::ChineseESP;
    use Data::Dumper;

    my $esp = Data::ChineseESP->new();
    print Dumper $esp->dump;


=head1 SUBROUTINES/METHODS

=head2 new

    my $esp = Data::ChineseESP->new();

=head2 dump

    my $hash_ref = $esp->dump;

=cut

sub new {
    my $class = shift;
    bless {},$class;
}


sub dump {
    my $self = shift;

    my $esp_data = 
    {
        '163.com' => { 'owner' => 'Netease INC',     'since' => '1997-09-14', },
        '126.com' => { 'owner' => 'Netease INC',     'since' => '1998-02-27', },
        'yeah.net' => { 'owner' => 'Netease INC',    'since' => '1997-08-19', },
        '188.com' => { 'owner' => 'Netease INC',     'since' => '1998-03-10', },
        '166.com' => { 'owner' => 'Netease INC',     'since' => '1998-03-10', },
        'netease.com' => { 'owner' => 'Netease INC', 'since' => '1998-04-08', },
        'sina.com' => { 'owner' => 'Sina INC',       'since' => '1998-09-15', },
        'sina.cn' => { 'owner' => 'Sina INC',        'since' => '2003-03-17', },
        'weibo.com' =>  { 'owner' => 'Sina INC',     'since' => '1999-03-20', },
        'sina.com.cn' => { 'owner' => 'Sina INC',    'since' => '1998-11-20', },
        'sohu.com' => { 'owner' => 'Sohu INC',       'since' => '1998-07-04', },
        'sogou.com' => { 'owner' => 'Sohu INC',      'since' => '2001-12-19', },
        'tom.com' => { 'owner' => 'Tom INC',         'since' => '1995-03-12', },
        '163.net' => { 'owner' => 'Tom INC',         'since' => '1997-09-15', },
        '21cn.net' => { 'owner' => 'China Telecom',  'since' => '1999-02-08', },
        '21cn.com' => { 'owner' => 'China Telecom',  'since' => '1999-02-08', },
        '189.cn' => { 'owner' => 'China Telecom',    'since' => '2004-05-04', },
        '139.com' => { 'owner' => 'China Mobile',    'since' => '1997-04-25', },
        'wo.cn' => { 'owner' => 'China Unicom',      'since' => '2013-12-27', },
        'wo.com.cn' => { 'owner' => 'China Unicom',  'since' => '2000-03-29', },
        'aliyun.com' => { 'owner' => 'Alibaba INC',  'since' => '2007-09-28', },
        'dingtalk.com' => { 'owner' => 'Alibaba INC','since' => '2014-07-01', },
        'taobao.com' => { 'owner' => 'Alibaba INC',  'since' => '2003-04-21', },
        'qq.com' => { 'owner' => 'Tencent INC',      'since' => '1995-05-03', },
        'qmail.com' => { 'owner' => 'Tencent INC',   'since' => '1996-07-09', },
        'foxmail.com' => { 'owner' => 'Tencent INC', 'since' => '1997-09-21', },
        '263.net' => { 'owner' => 'Capital Online',  'since' => '1998-05-03', },
        '2980.com' => { 'owner' => 'Duoyi INC',      'since' => '2003-09-16', },
    };

    return $esp_data;
}


=head1 AUTHOR

Joel Peng, C<< <jpeng at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-chineseesp at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ChineseESP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::ChineseESP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-ChineseESP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-ChineseESP>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Data-ChineseESP>

=item * Search CPAN

L<https://metacpan.org/release/Data-ChineseESP>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Joel Peng.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Data::ChineseESP
