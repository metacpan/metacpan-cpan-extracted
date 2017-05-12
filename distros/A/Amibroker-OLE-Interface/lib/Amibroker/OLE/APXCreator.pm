package Amibroker::OLE::APXCreator;

use 5.006;
use strict;
use warnings;
use Path::Tiny;
use File::Slurp;
use Carp;
use IO::File;

=head1 NAME

Amibroker::OLE::APXCreator - A simple interface to create .apx extension file for accessing Amibroker analysis document from external scripts.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

	use Amibroker::OLE::APXCreator;
	my $new_apx_file = create_apx_file( {
                                        afl_file   => 'test_afl.afl',
                                        symbol     => 'ADANIPORTS-I',
                                        timeframe  => '20-minute',
                                        from       => '01-09-2015',
                                        to         => '20-09-2015',
                                        range_type => 0,
                                        apply_to   => 1
                                    } );

=head1 DESCRIPTION

This module helps in creating apx file (i.e. file with .apx extention), which is the basic input file for running Amibroker analysis externally through OLE automation.

Creating this file automatically is a challenge as Amibroker is very sensitive to any changes with respect to apx file.
If there is even a space missed in creating it, then it will not process it.
So, to make life easier, this module handles the creation of the file as required by the amibroker.

NOTE: Please ensure to provide all the required necessary fields.

	use Amibroker::OLE::APXCreator;
	my $new_apx_file = create_apx_file( {
                                        afl_file   => 'path_to_the_location_of_the_afl_file',
                                        symbol     => 'symbol_name',
                                        timeframe  => 'timeframe',
                                        from       => 'from_date',
                                        to         => 'to_date',
                                        range_type => range_type_in_number,
                                        apply_to   => apply_to_in_number
                                     } );

=head2 REQUIRED PARAMETERS

=over 8

=item B<afl_file>

Complete Path to the AFL file, that you need to backtest or optimize or scan etc.
Eg: afl_file => 'C:/Amibroker/Stratergy/Release/IBM.afl'

=item B<symbol>

The Symbol name should match with the symbol names in the Amibroker database
Eg: symbol => 'IBM-I' or
    symbol => 'IBM'
    (The name should exactly match with your database symbol)  

=item B<timeframe>

    Default available timeframe with Amibroker.
    yearly    
    quarterly  
    monthly   
    weekly    
    daily     
    day/night 
    hourly     
    15-minute 
    5-minute 
    1-minute   
    3-minute 
    7-minute  
    10-minute
    12-minute 
    20-minute 

If you want to have your custom defined timeframe then you need to update here
Amibroker -> Tools -> Preferences -> Intraday Tab -> Custom Time Intervals

=item B<from>

    from date, Eg: from => '01-12-2010' (for 1st December 2010 date)
                   from => '2010-12-01' (for 1st December 2010 date)
                   from => '2010-01-12' (for 1st December 2010 date)
                   from => '12-01-2010' (for 1st December 2010 date)
                   from => '12-2010-01' (for 1st December 2010 date)
Date format should match your Amibroker date format : Usually it is windows system time settings
Please check your amibroker date format and send the appropriate date format

=item B<to>

    to date, Eg: to => '31-05-2015' (for 31st May 2015 date)
Date format should match your Amibroker date format : Usually it is windows system time settings
Please check your amibroker date format and send the appropriate date format

=item B<apx_file>

complete path of the apx file where you want to create this file.
    Eg: apx_file => 'C:/IBM.apx'

=item B<range_type>

    Range in Amibroker analysis refers to
        'All Quotes'      = 0  
        '1 recent bar(s)' = 1
        '1 recent day(s)' = 2
        'From-To-dates'   = 3
    So provide range number accordingly

=item B<apply_to>

    Apply the settings to
	   '*All Symbols' = 0
	   '*Current'     = 1
	   '*Filter'      = 2

=back

=head2 OPTIONAL PARAMETERS

=over 1

=item B<periodicity>

This module assumes that there is no change in the amibroker custom time interval settings.
i.e Amibroker -> Tools -> Preferences -> Intraday Tab -> Custom Time Intervals.

Amibroker assigns a value to every intervals  
    Eg: (Below are the default Amibroker intervals provided and their default values)
    yearly     = -4
    quarterly  = -3
    monthly    = -2
    weekly     = -1
    daily      =  0
    day/night  =  1
    hourly     =  2
    15-minute  =  3
    5-minute   =  4
    1-minute   =  5
    3-minute   = 10
    7-minute   = 11
    10-minute  = 12
    12-minute  = 13
    20-minute  = 14

If you happen to change the custom time intervals, then the amibroker default values may change.
In that case you have to find out the actual value of the custom interval and pass as the parameter.

    Eg:
    periodicity => -5 
    (you can find this out by manually saving the apx file and checking the periodicity field)

How to create apx file manually:

=over 3 

=item * Open Amibroker -> Analysis window -> Settings

=item * Edit settings as per your requirement

=item * Menu-> File-> Save_AS -> select (.apx extenstion)

=back

For more infor on apx file, check this forum : L<http://amibrokerforum.proboards.com/thread/57/analysis-project-files-apx>

=back

=cut

#
# Create the apx file that goes as input to the amibroker engine
#
my %periods = (
    'yearly'    => -4,
    'quarterly' => -3,
    'monthly'   => -2,
    'weekly'    => -1,
    'daily'     => 0,
    'day/night' => 1,
    'hourly'    => 2,
    '15-minute' => 3,
    '5-minute'  => 4,
    '1-minute'  => 5,
    '3-minute'  => 10,
    '7-minute'  => 11,
    '10-minute' => 12,
    '12-minute' => 13,
    '20-minute' => 14
);

sub create_apx_file {
    my @list = @_;
    my $args = _check_valid_args(@list);
    if ( !$args->{timeframe} ) {
        croak( '[ERROR}: No timeframe passed (Required parameter) : ' . "\n" );
    }
    if ( !$args->{periodicity} ) {
        $args->{periodicity} = lc( $args->{timeframe} );
    }
    if ( !$args->{periodicity} ) {
        croak(  '[ERROR}: No periodicity found for given timeframe '
              . $args->{timeframe}
              . "\n" );
    }
    if ( !-e $args->{afl_file} ) {
        croak( '[ERROR}: AFL file not present at:' . $args->{afl_file} . "\n" );
    }
    if ( !$args->{symbol} ) {
        croak( '[ERROR}: Symbol name not passed (Required parameter):' . "\n" );
    }
    if ( !$args->{from} ) {
        croak(
            '[ERROR}: from date is not passed (Required parameter):' . "\n" );
    }
    if ( !$args->{to} ) {
        croak( '[ERROR}: to date is not passed (Required parameter):' . "\n" );
    }
    if ( !$args->{apx_file} ) {
        print
'[WARN]: apx_file is not passed, by default your apx file name will be : C:/'
          . $args->{symbol} . '.apx' . "\n";
        $args->{apx_file} = 'C:/' . $args->{symbol} . '.apx';
    }
    if ( !defined( $args->{range_type} ) ) {
        croak(  '[ERROR}: range_type value is not passed, (Required parameter):'
              . "\n" );
    }
    if ( !defined( $args->{apply_to} ) ) {
        croak(  '[ERROR}: apply_to value is not passed, (Required parameter):'
              . "\n" );
    }
    my $text_dummy = 'XXXX';

    $args->{from} = $args->{from} . ' 00:00:00';
    my $afl_data = slurp_afl( $args->{afl_file} );
    $args->{afl_file} =~ s/\//\\/gx;
    $args->{afl_file} =~ s/\\/\\\\/gx;
    my $afl = convert_afl_text_for_amibroker($afl_data);
    my $fh  = IO::File->new("> $args->{apx_file}");
    while ( my $data = <DATA> ) {
        $data =~ s/
                    \<Symbol\>
                    $text_dummy
                    \<\/Symbol\>
                    /
                    \<Symbol\>
                    $args->{symbol}
                    \<\/Symbol\>
                 /gx;
        $data =~ s/
                    \<FormulaPath\>
                    $text_dummy
                    \<\/FormulaPath\>
                  /
                    \<FormulaPath\>
                    $args->{afl_file}
                    \<\/FormulaPath\>
                  /gx;
        $data =~ s/
                    \<FormulaContent\>
                    $text_dummy
                    \<\/FormulaContent\>
                    /
                    \<FormulaContent\>
                    $afl\<\/FormulaContent\>
                    /gx;
        $data =~ s/
                    \<Periodicity\>
                    $text_dummy
                     \<\/Periodicity\>
                 /
                    \<Periodicity\>
                    $periods{$args->{periodicity}}
                    \<\/Periodicity\>
                 /gx;
        $data =~ s/
                    \<FromDate\>
                    $text_dummy
                    \<\/FromDate\>
                 /
                    \<FromDate\>
                    $args->{from}
                    \<\/FromDate\>
                 /gx;
        $data =~ s/
                    \<ToDate\>
                    $text_dummy
                    \<\/ToDate\>
                  /
                    \<ToDate\>
                    $args->{to}
                    \<\/ToDate\>
                 /gx;
        $data =~ s/
                    \<ApplyTo\>
                    $text_dummy
                    \<\/ApplyTo\>
                  /
                    \<ApplyTo\>
                    $args->{apply_to}
                    \<\/ApplyTo\>
                 /gx;
        $data =~ s/
                    \<RangeType\>
                    $text_dummy
                    \<\/RangeType\>
                  /
                    \<RangeType\>
                    $args->{range_type}
                    \<\/RangeType\>
                /gx;
        print $fh $data;
    }
    undef $fh;    # automatically closes the file
    autoflush STDOUT 1;
    return $args->{apx_file};
}

#
# Gulp the file into a string
#
sub slurp_afl {
    my $text = File::Slurp::read_file(shift);
    return $text;
}

#
# Convert text that is gulped into a scalar variable and modifiy accordingly to be loaded to Amibroker.
#
sub convert_afl_text_for_amibroker {
    my $text = shift;
    $text =~ s/\&/\&amp\;/g;
    $text =~ s/\\n/\\\\n/g;
    $text =~ s/\R/\\r\\n/g;
    $text =~ s/\t/\\t/g;
    $text =~ s/\</\&lt\;/g;
    $text =~ s/\>/\&gt\;/g;
    unless ( $text =~ /\\r\\n$/ ) {
        $text =~ s/$/\\r\\n/g;
    }
    return $text;
}

sub _check_valid_args {
    my @list = @_;
    my %args_permitted = map { $_ => 1 } (
        qw|
          afl_file
          symbol
          timeframe
          from
          to
          apx_file
          periodicity
          apply_to
          range_type
          |
    );
    my @bad_args = ();
    my $arg      = pop @list;
    for my $k ( sort keys %{$arg} ) {
        push @bad_args, $k unless $args_permitted{$k};
    }
    croak("Unrecognized option(s) passed to Amibroker OLE: @bad_args")
      if @bad_args;
    return $arg;
}

=head1 AUTHOR

Babu Prasad HP, C<< <bprasad at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-amibroker-ole-apxcreator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Amibroker-OLE-APXCreator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Amibroker::OLE::APXCreator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Amibroker-OLE-APXCreator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Amibroker-OLE-APXCreator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Amibroker-OLE-APXCreator>

=item * Search CPAN

L<http://search.cpan.org/dist/Amibroker-OLE-APXCreator/>

=back


=head1 ACKNOWLEDGEMENTS

I would like to thank Mr.Pannag M for supporting me in writing this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Babu Prasad HP.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Amibroker::OLE::APXCreator

__DATA__
<?xml version="1.0" encoding="ISO-8859-1"?>
<AmiBroker-Analysis CompactMode="0">
<General>
<FormatVersion>1</FormatVersion>
<Symbol>XXXX</Symbol>
<FormulaPath>XXXX</FormulaPath>
<FormulaContent>XXXX</FormulaContent>
<ApplyTo>XXXX</ApplyTo>
<RangeType>XXXX</RangeType>
<RangeAmount>1</RangeAmount>
<FromDate>XXXX</FromDate>
<ToDate>XXXX</ToDate>
<SyncOnSelect>0</SyncOnSelect>
<RunEvery>0</RunEvery>
<RunEveryInterval>5min</RunEveryInterval>
<IncludeFilter>
<ExcludeMode>0</ExcludeMode>
<MarketID>-1</MarketID>
<GroupID>-1</GroupID>
<SectorID>-1</SectorID>
<IndustryID>-1</IndustryID>
<WatchListID>-1</WatchListID>
<Favourite>0</Favourite>
<Index>0</Index>
<GICSID>-1</GICSID>
<ICBID>-1</ICBID>
</IncludeFilter>
<ExcludeFilter>
<ExcludeMode>0</ExcludeMode>
<MarketID>-1</MarketID>
<GroupID>-1</GroupID>
<SectorID>-1</SectorID>
<IndustryID>-1</IndustryID>
<WatchListID>-1</WatchListID>
<Favourite>0</Favourite>
<Index>0</Index>
<GICSID>-1</GICSID>
<ICBID>-1</ICBID>
</ExcludeFilter>
</General>
<BacktestSettings>
<InitialEquity>10000</InitialEquity>
<TradeFlags>3</TradeFlags>
<MaxLossStopMode>0</MaxLossStopMode>
<MaxLossStopValue>0</MaxLossStopValue>
<MaxLossStopAtStop>0</MaxLossStopAtStop>
<ProfitStopMode>0</ProfitStopMode>
<ProfitStopValue>0</ProfitStopValue>
<ProfitStopAtStop>0</ProfitStopAtStop>
<TrailingStopMode>0</TrailingStopMode>
<TrailingStopPeriods>0</TrailingStopPeriods>
<TrailingStopValue>0</TrailingStopValue>
<TrailingStopAtStop>0</TrailingStopAtStop>
<CommissionMode>0</CommissionMode>
<CommissionValue>0</CommissionValue>
<BuyPriceField>0</BuyPriceField>
<BuyDelay>0</BuyDelay>
<SellPriceField>0</SellPriceField>
<SellDelay>0</SellDelay>
<ShortPriceField>0</ShortPriceField>
<ShortDelay>0</ShortDelay>
<CoverPriceField>0</CoverPriceField>
<CoverDelay>0</CoverDelay>
<ReportSystemFormula>0</ReportSystemFormula>
<ReportSystemSettings>0</ReportSystemSettings>
<ReportOverallSummary>1</ReportOverallSummary>
<ReportSummary>1</ReportSummary>
<ReportTradeList>1</ReportTradeList>
<LoadRemainingQuotes>1</LoadRemainingQuotes>
<Periodicity>XXXX</Periodicity>
<InterestRate>0</InterestRate>
<ReportOutPositions>1</ReportOutPositions>
<UseConstantPriceArrays>0</UseConstantPriceArrays>
<PointsOnlyTest>1</PointsOnlyTest>
<AllowShrinkingPosition>0</AllowShrinkingPosition>
<RangeType>0</RangeType>
<RangeLength>0</RangeLength>
<RangeFromDate>15-08-2015 00:00:00</RangeFromDate>
<RangeToDate>15-08-2015</RangeToDate>
<ApplyTo>1</ApplyTo>
<FilterQty>2</FilterQty>
<IncludeFilter>
<ExcludeMode>0</ExcludeMode>
<MarketID>-1</MarketID>
<GroupID>-1</GroupID>
<SectorID>-1</SectorID>
<IndustryID>-1</IndustryID>
<WatchListID>-1</WatchListID>
<Favourite>0</Favourite>
<Index>0</Index>
<GICSID>-1</GICSID>
<ICBID>-1</ICBID>
</IncludeFilter>
<ExcludeFilter>
<ExcludeMode>0</ExcludeMode>
<MarketID>-1</MarketID>
<GroupID>-1</GroupID>
<SectorID>-1</SectorID>
<IndustryID>-1</IndustryID>
<WatchListID>-1</WatchListID>
<Favourite>0</Favourite>
<Index>0</Index>
<GICSID>-1</GICSID>
<ICBID>-1</ICBID>
</ExcludeFilter>
<UseOptimizedEvaluation>0</UseOptimizedEvaluation>
<BacktestRangeType>0</BacktestRangeType>
<BacktestRangeLength>0</BacktestRangeLength>
<BacktestRangeFromDate>29-11-2013 00:00:00</BacktestRangeFromDate>
<BacktestRangeToDate>26-12-2013</BacktestRangeToDate>
<MarginRequirement>100</MarginRequirement>
<SameDayStops>0</SameDayStops>
<RoundLotSize>0</RoundLotSize>
<TickSize>0</TickSize>
<DrawdownPriceField>0</DrawdownPriceField>
<ReverseSignalForcesExit>1</ReverseSignalForcesExit>
<NoDefaultColumns>0</NoDefaultColumns>
<AllowSameBarExit>1</AllowSameBarExit>
<ExtensiveOptimizationWarning>0</ExtensiveOptimizationWarning>
<WaitForBackfill>0</WaitForBackfill>
<MaxRanked>4</MaxRanked>
<MaxTraded>4</MaxTraded>
<MaxTracked>100</MaxTracked>
<PortfolioReportMode>2</PortfolioReportMode>
<MinShares>0.1</MinShares>
<SharpeRiskFreeReturn>5</SharpeRiskFreeReturn>
<PortfolioMode>0</PortfolioMode>
<PriceBoundCheck>1</PriceBoundCheck>
<AlignToReferenceSymbol>0</AlignToReferenceSymbol>
<ReferenceSymbol>^DJI</ReferenceSymbol>
<UPIRiskFreeReturn>5.4</UPIRiskFreeReturn>
<NBarStopMode>0</NBarStopMode>
<NBarStopValue>0</NBarStopValue>
<NBarStopReentryDelay>0</NBarStopReentryDelay>
<MaxLossStopReentryDelay>0</MaxLossStopReentryDelay>
<ProfitStopReentryDelay>0</ProfitStopReentryDelay>
<TrailingStopReentryDelay>0</TrailingStopReentryDelay>
<AddFutureBars>0</AddFutureBars>
<DistChartSpacing>5</DistChartSpacing>
<ProfitDistribution>1</ProfitDistribution>
<MAFEDistribution>0</MAFEDistribution>
<IndividualDetailedReports>0</IndividualDetailedReports>
<PortfolioReportTradeList>0</PortfolioReportTradeList>
<LimitTradeSizeAsPctVol>10</LimitTradeSizeAsPctVol>
<DisableSizeLimitWhenVolumeIsZero>1</DisableSizeLimitWhenVolumeIsZero>
<UsePrevBarEquityForPosSizing>0</UsePrevBarEquityForPosSizing>
<NBarStopHasPriority>0</NBarStopHasPriority>
<UseCustomBacktestProc>0</UseCustomBacktestProc>
<CustomBacktestProcFormulaPath/>
<MinPosValue>0</MinPosValue>
<MaxPosValue>0</MaxPosValue>
<ChartInterval>3600</ChartInterval>
<DisableRuinStop>0</DisableRuinStop>
<OptTarget>CAR/MDD</OptTarget>
<WFMode>0</WFMode>
<GenerateReport>0</GenerateReport>
<MaxLongPos>0</MaxLongPos>
<MaxShortPos>0</MaxShortPos>
<SeparateLongShortRank>0</SeparateLongShortRank>
<TotalSymbolQty>0</TotalSymbolQty>
<EnableUserReportCharts>1</EnableUserReportCharts>
<ChartWidth>500</ChartWidth>
<ChartHeight>300</ChartHeight>
<SettlementDelay>0</SettlementDelay>
<PortfolioReportSystemFormula>0</PortfolioReportSystemFormula>
</BacktestSettings>
</AmiBroker-Analysis>
