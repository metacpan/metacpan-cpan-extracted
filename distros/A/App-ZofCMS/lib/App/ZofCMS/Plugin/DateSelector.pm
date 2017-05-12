package App::ZofCMS::Plugin::DateSelector;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use HTML::Template;
use Time::Local (qw/timelocal/);

my %Options_Dispatch = (
    year    => \&_prepare_year,
    month   => \&_prepare_month,
    day     => \&_prepare_day,
    hour    => \&_prepare_hour,
    minute  => \&_prepare_minute,
    second  => \&_prepare_second,
);

my @Months = (qw/
    January February March     April   May      June
    July    August   September October November December
/);

sub new { bless {}, shift; }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    my $conf = delete $template->{plug_date_selector}
                || delete $config->conf->{plug_date_selector};

    ref $conf
        or return;

    unless ( ref $conf eq 'ARRAY' ) {
        $conf = [ $conf ];
    }

    for my $selector ( @$conf ) {
        $selector = {
            class           => 'date_selector',
            #id              => 'date_selector',
            q_name          => 'date',
            t_name          => 'date_selector',
            d_name          => 'date_selector',
            start           => time() - 30000000,
            end             => time() + 30000000,
            interval_step   => 'minute',
            interval_max    => 'year',
            minute_step     => 5,
            second_step     => 10,
            %$selector,
        };

        my @fields;
        for ( qw/year month day hour minute second/ ) {
            if ( $_ eq $selector->{interval_max} .. $_ eq $selector->{interval_step} ) {
                push @fields, $_;
            }
        }

        my %query_dates;
        @query_dates{ qw/year month day hour minute second/ } = (localtime)[reverse 0..5];
        my $have_date = 1;
        for my $field ( @fields ) {
            my $value = $query->{ $selector->{q_name} . '_' . $field };
            if ( defined $value ) {
                $query_dates{ $field } = $value;
            }
            else {
                $have_date = 0;
            }
        }
        if ( $have_date ) {
            my $time = timelocal( @query_dates{ qw/second minute hour day month year/ } );
            $template->{d}{ $selector->{d_name} } = {
                time        => $time,
                localtime   => scalar(localtime $time),
                bits        => \%query_dates,
            };
        }

        my @html_code;
        for my $field_index ( 0 .. $#fields ) {
            my $field = $fields[ $field_index ];

            my $t = HTML::Template->new_scalar_ref( \ $self->_html_template );

            $t->param(
                (
                    ( defined $selector->{id} and $field_index == 0 )
                    ? ( select_id => $selector->{id} ) : ()
                ),
                select_class    => $selector->{class},
                select_name     => $selector->{q_name} . '_' . $field,
                options         => $Options_Dispatch{ $field }->( $selector, $query ),
            );

            push @html_code, $t->output;
        }

        $template->{t}{ $selector->{t_name} } = join "\n", @html_code;
    }
}

sub _prepare_year {
    my ( $s, $q ) = @_;

    my @out;
    if ( $s->{interval_max} eq 'year' ) {
        @out = (localtime $s->{start})[5]+1900 .. (localtime $s->{end})[5]+1900;
    }
    else {
        @out = 1900 + (localtime)[5];
    }

    my $q_value = $q->{ $s->{q_name} . '_' . 'year' };
    return [
        map +{
            value       => $out[$_] - 1900,
            vis_value   => $out[$_],

            selected    =>
            (
                ( not defined $q_value and $_ == 0 )
                or
                ( defined $q_value and $q_value eq $out[$_]-1900 )
            ) ? 1 : 0,

        }, 0..$#out,
    ];
}

sub _prepare_month {
    my ( $s, $q ) = @_;

    my @out;
    if ( $s->{interval_max} eq 'month'
        and (localtime $s->{start})[5] == (localtime $s->{end})[5]
    ) {
        @out = (localtime $s->{start})[4] .. (localtime $s->{end})[4];
    }
    else {
        @out = 0..11;
    }

    my $q_value = $q->{ $s->{q_name} . '_' . 'month' };
    return [
        map +{
            value       => $out[$_],
            vis_value   => $Months[ $out[$_] ],

            selected    =>
            (
                ( not defined $q_value and $_ == 0 )
                or
                ( defined $q_value and $q_value eq $out[$_] )
            ) ? 1 : 0,

        }, 0..$#out,
    ];
}

sub _prepare_day {
    my ( $s, $q ) = @_;

    my @out;
    if ( $s->{interval_max} eq 'day'
        and (localtime $s->{start})[5] == (localtime $s->{end})[5]
        and (localtime $s->{start})[4] == (localtime $s->{end})[4]
    ) {
        @out = (localtime $s->{start})[3] .. (localtime $s->{end})[3];
    }
    else {
        @out = 1 .. 31;
    }

    my $q_value = $q->{ $s->{q_name} . '_' . 'day' };
    return [
        map +{
            value       => $out[$_],
            vis_value   => "Day: $out[$_]",

            selected    =>
            (
                ( not defined $q_value and $_ == 0 )
                or
                ( defined $q_value and $q_value eq $out[$_] )
            ) ? 1 : 0,

        }, 0..$#out,
    ];
}

sub _prepare_hour {
    my ( $s, $q ) = @_;

    my @out;
    if ( $s->{interval_max} eq 'hour'
        and (localtime $s->{start})[5] == (localtime $s->{end})[5]
        and (localtime $s->{start})[4] == (localtime $s->{end})[4]
        and (localtime $s->{start})[3] == (localtime $s->{end})[3]
    ) {
        @out = (localtime $s->{start})[2] .. (localtime $s->{end})[2];
    }
    else {
        @out = 0..23;
    }


    my $q_value = $q->{ $s->{q_name} . '_' . 'hour' };
    return [
        map +{
            value       => $out[$_],
            vis_value   => "Hour: $out[$_]",

            selected    =>
            (
                ( not defined $q_value and $_ == 0 )
                or
                ( defined $q_value and $q_value eq $out[$_] )
            ) ? 1 : 0,

        }, 0..$#out,
    ];
}

sub _prepare_minute {
    my ( $s, $q ) = @_;

    my @out;
    if ( $s->{interval_max} eq 'minute'
        and (localtime $s->{start})[5] == (localtime $s->{end})[5]
        and (localtime $s->{start})[4] == (localtime $s->{end})[4]
        and (localtime $s->{start})[3] == (localtime $s->{end})[3]
        and (localtime $s->{start})[2] == (localtime $s->{end})[2]
    ) {
        @out = (localtime $s->{start})[1] .. (localtime $s->{end})[1];
    }
    else {
        @out = 0..59;
    }

    @out = grep { not $_ % $s->{minute_step} } @out;

    my $q_value = $q->{ $s->{q_name} . '_' . 'minute' };
    return [
        map +{
            value       => $out[$_],
            vis_value   => sprintf("Minute: %02d", $out[$_]),

            selected    =>
            (
                ( not defined $q_value and $_ == 0 )
                or
                ( defined $q_value and $q_value eq $out[$_] )
            ) ? 1 : 0,

        }, 0..$#out,
    ];
}

sub _prepare_second {
    my ( $s, $q ) = @_;

    my @out;
    if ( $s->{interval_max} eq 'minute'
        and (localtime $s->{start})[5] == (localtime $s->{end})[5]
        and (localtime $s->{start})[4] == (localtime $s->{end})[4]
        and (localtime $s->{start})[3] == (localtime $s->{end})[3]
        and (localtime $s->{start})[2] == (localtime $s->{end})[2]
    ) {
        @out = (localtime $s->{start})[1] .. (localtime $s->{end})[1];
    }
    else {
        @out = 0..59;
    }

    @out = grep { not $_ % $s->{second_step} } @out;

    my $q_value = $q->{ $s->{q_name} . '_' . 'second' };
    return [
        map +{
            value       => $out[$_],
            vis_value   => sprintf("Second: %02d", $out[$_]),

            selected    =>
            (
                ( not defined $q_value and $_ == 0 )
                or
                ( defined $q_value and $q_value eq $out[$_] )
            ) ? 1 : 0,

        }, 0..$#out,
    ];
}

sub _html_template {
    return <<'TEMPLATE_END';
<select name="<tmpl_var escape='html' name='select_name'>" class="<tmpl_var escape='html' name='select_class'>"<tmpl_if name='select_id'> id="<tmpl_var escape='html' name='select_id'>"</tmpl_if>><tmpl_loop name='options'>
    <option value="<tmpl_var escape='html' name='value'>"<tmpl_if name='selected'> selected</tmpl_if>><tmpl_var escape='html' name='vis_value'></option></tmpl_loop>
</select>
TEMPLATE_END
}


1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::DateSelector - plugin to generate and "parse" <select>s for date/time input

=head1 SYNOPSIS

In ZofCMS Template or Main Config File

    # the Sub plugin is used only for demonstration here

    plugins => [ { DateSelector => 2000 }, { Sub => 3000 } ],

    plug_date_selector => {
        class           => 'date_selector',
        id              => 'date_selector',
        q_name          => 'date',
        t_name          => 'date_selector',
        start           => time() - 30000000,
        end             => time() + 30000000,
        interval_step   => 'minute',
        interval_max    => 'year',
    },

    plug_sub => sub {
        my $t = shift;
        $t->{t}{DATE} = "[$t->{d}{date_selector}{localtime}]";
    },

In L<HTML::Template> template:

    <form...

        <label for="date_selector">When: </label><tmpl_var name="date_selector">

    .../form>

    <tmpl_if name="DATE">
        <p>You selected: <tmpl_var name="DATE"></p>
    <tmpl_else>
        <p>You did not select anything yet</p>
    </tmpl_if>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to generate several
C<< <select> >> elements for date and time selection by the user. Plugin also provides means
to "parse" those C<< <select> >>s from the query to generate either epoch time, same string
as C<localtime()> or access each selection individually from a hashref.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [ qw/DateSelector/ ],

You obviously need to add the plugin to the list of plugins to execute. The plugin does not
provide any input checking and sticks the "parse" of query into the C<{d}> special key in
ZofCMS Template, thus you'd very likely to use this plugin in combination with some other
plugin.

=head2 C<plug_date_selector>

    plug_date_selector => {
        class           => 'date_selector',
        id              => 'date_selector',
        q_name          => 'date',
        t_name          => 'date_selector',
        d_name          => 'date_selector',
        start           => time() - 30000000,
        end             => time() + 30000000,
        interval_step   => 'minute',
        interval_max    => 'year',
    }

    plug_date_selector => [
        {
            class           => 'date_selector1',
            id              => 'date_selector1',
            q_name          => 'date1',
            t_name          => 'date_selector1',
            d_name          => 'date_selector1',
        },
        {
            class           => 'date_selector2',
            id              => 'date_selector2',
            q_name          => 'date2',
            t_name          => 'date_selector2',
            d_name          => 'date_selector2',
        }
    ]

Plugin will not run unless C<plug_date_selector> first-level key is specified in either
ZofCMS Template or Main Config File. When specified in both, ZofCMS Template and Main Config
File, then the value set in ZofCMS Template takes precedence. To use the plugin with all
of its defaults use C<< plug_date_selector => {} >>

The C<plug_date_selector> key takes either hashref or an arrayref as a value. If the value
is a hashref, it is the same as specifying an arrayref with just that hashref in it. Each
hashref represents a separate "date selector", i.e. a set of C<< <select> >> elements for
date selection. The possible keys/values of each of those hashrefs are as follows:

=head3 C<class>

    class => 'date_selector',

B<Optional>. Specifies the C<class=""> attribute to stick on every generated C<< <select> >>
element in the date selector. B<Defaults to:> C<date_selector>

=head3 C<id>

    id => 'date_selector',

B<Optional>. Specifies the C<id=""> attribute to stick on the B<first> generated
C<< <select> >> element in the date selector. B<By default> is not specified, i.e. no C<id="">
will be added.

=head3 C<q_name>

    q_name => 'date',

B<Optional>. Specifies the "base" B<q>uery parameter name for generated C<< <select> >>
elements.
Each of those elements will have its C<name=""> attribute made from C<$q_name . '_' . $type>,
where C<$q_name> is the value of C<q_name> key and C<$type> is the type of the
C<< <select> >>, the types are as follows: C<year>, C<month>, C<day>, C<hour>, C<minute>
and C<second>. B<Defaults to:> C<date>

=head3 C<t_name>

    t_name => 'date_selector',

B<Optional>. Specifies the name of the key in C<{t}> ZofCMS Template special key where to
stick HTML code for generated C<< <select> >>s. B<Defaults to:> C<date_selector>, thus you'd
use C<< <tmpl_var name='date_selector'> >> to insert HTML code.

=head3 C<d_name>

    d_name => 'date_selector',

B<Optional>. If plugin sees that the query contains B<all> of the parameters from a given
"date selector", then it will set the C<d_name> key in C<{d}> ZofCMS Template special key
with a hashref that contains three keys:

    $VAR1 = {
        'time' => 1181513455,
        'localtime' => 'Sun Jun 10 18:10:55 2007',
        'bits' => {
            'hour' => '18',
            'minute' => '10',
            'second' => 55,
            'month' => '5',
            'day' => '10',
            'year' => 107
        }
    };

=head4 C<time>

    'time' => 1181513455,

The C<time> key will contain the epoch time of the date that user selected (i.e. as C<time()>
would output).

=head4 C<localtime>

    'localtime' => 'Sun Jun 10 18:10:55 2007',

The C<localtime> key will contain the "date string" of the selected date (i.e. output of
C<localtime()>).

=head4 C<bits>

    'bits' => {
        'hour' => '18',
        'minute' => '10',
        'second' => 55,
        'month' => '5',
        'day' => '10',
        'year' => 107
    }

The C<bits> key will contain a B<hashref>, with individual "bits" of the selected date. The
"bits" are keys in the hashref and are as follows: year, month, day, hour, minute and second.
If your date selector's range does not cover all the values (e.g. has only month and day)
(see C<interval_step> and C<interval_max> options below) then the B<missing values> will
be taken from the output of C<localtime()>. The values of each of these "bits" are in
the same format as C<localtime()> would give them to you, i.e. to get the full year you'd
do bits->{year} + 1900.

=head3 C<start>

    start => time() - 30000000,

B<Optional>. The plugin will generate values for C<< <select> >> elements to cover a certain
period of time. The C<start> and C<end> (see below) parameters take the number of seconds
from epoch (i.e. same as return of C<time()>) as values and C<start> indicates the start
of the period to cover and C<end> indicates the end of the time period to cover. B<Defaults
to:> C<time() - 30000000>

=head3 C<end>

    end => time() + 30000000,

B<Optional>. See description of C<start> right above. B<Defaults to:> C<time() + 30000000>

=head3 C<interval_step>

    interval_step   => 'minute',

B<Optional>. Specifies the "step", or the minimum unit of time the user would be able to
select. Valid values (all lowercase) are as follows: C<year>, C<month>, C<day>, C<hour>,
C<minute> and C<second>. B<Defaults to:> C<minute>

=head3 C<interval_max>

    interval_max => 'year',

B<Optional>. Specifies the maximum unit of time the user would be able to select.
Valid values (all lowercase) are as follows: C<year>, C<month>, C<day>, C<hour>,
C<minute> and C<second>. B<Defaults to:> C<year>

=head3 C<minute_step>

    minute_step => 5,

B<Optional>. Specifies the "step" of minutes to display, in other words, when C<minute_step>
is set to C<10>, then in the "minutes" C<< <select> >>
the plugin will generate only C<< <option> >>s 0, 10, 20, 30, 40 and 50. B<Defaults to:>
C<5> (increments of 5 minutes).

=head3 C<second_step>

    second_step => 10,

B<Optional>. Specifies the "step" of seconds to display, in other words, when C<second_step>
is set to C<10>, then in the "minutes" C<< <select> >>
the plugin will generate only C<< <option> >>s 0, 10, 20, 30, 40 and 50. B<Defaults to:>
C<5> (increments of 5 minutes).

=head1 HTML::Template VARIABLES

See description of C<t_name> argument above. The value of C<t_name> specifies the name
of the C<< <tmpl_var name=""> >> plugin will generate. Note that there could be several of
these of you are generating several date selectors.

=head1 GENERATED HTML CODE

The following is a sample of the generated code with all the defaults left intact:

    <select name="date_year" class="date_selector">
        <option value="107" selected>2007</option>
        <option value="108">2008</option>
        <option value="109">2009</option>
    </select>

    <select name="date_month" class="date_selector">
        <option value="0" selected>January</option>
        <option value="1">February</option>
        <option value="2">March</option>
        <option value="3">April</option>
        <option value="4">May</option>
        <option value="5">June</option>
        <option value="6">July</option>
        <option value="7">August</option>
        <option value="8">September</option>
        <option value="9">October</option>
        <option value="10">November</option>
        <option value="11">December</option>
    </select>

    <select name="date_day" class="date_selector">
        <option value="1" selected>Day: 1</option>
        <option value="2">Day: 2</option>
        <option value="3">Day: 3</option>
        <option value="4">Day: 4</option>
        <option value="5">Day: 5</option>
        <option value="6">Day: 6</option>
        <option value="7">Day: 7</option>
        <option value="8">Day: 8</option>
        <option value="9">Day: 9</option>
        <option value="10">Day: 10</option>
        <option value="11">Day: 11</option>
        <option value="12">Day: 12</option>
        <option value="13">Day: 13</option>
        <option value="14">Day: 14</option>
        <option value="15">Day: 15</option>
        <option value="16">Day: 16</option>
        <option value="17">Day: 17</option>
        <option value="18">Day: 18</option>
        <option value="19">Day: 19</option>
        <option value="20">Day: 20</option>
        <option value="21">Day: 21</option>
        <option value="22">Day: 22</option>
        <option value="23">Day: 23</option>
        <option value="24">Day: 24</option>
        <option value="25">Day: 25</option>
        <option value="26">Day: 26</option>
        <option value="27">Day: 27</option>
        <option value="28">Day: 28</option>
        <option value="29">Day: 29</option>
        <option value="30">Day: 30</option>
        <option value="31">Day: 31</option>
    </select>

    <select name="date_hour" class="date_selector">
        <option value="0" selected>Hour: 0</option>
        <option value="1">Hour: 1</option>
        <option value="2">Hour: 2</option>
        <option value="3">Hour: 3</option>
        <option value="4">Hour: 4</option>
        <option value="5">Hour: 5</option>
        <option value="6">Hour: 6</option>
        <option value="7">Hour: 7</option>
        <option value="8">Hour: 8</option>
        <option value="9">Hour: 9</option>
        <option value="10">Hour: 10</option>
        <option value="11">Hour: 11</option>
        <option value="12">Hour: 12</option>
        <option value="13">Hour: 13</option>
        <option value="14">Hour: 14</option>
        <option value="15">Hour: 15</option>
        <option value="16">Hour: 16</option>
        <option value="17">Hour: 17</option>
        <option value="18">Hour: 18</option>
        <option value="19">Hour: 19</option>
        <option value="20">Hour: 20</option>
        <option value="21">Hour: 21</option>
        <option value="22">Hour: 22</option>
        <option value="23">Hour: 23</option>
    </select>

    <select name="date_minute" class="date_selector">
        <option value="0" selected>Minute: 00</option>
        <option value="5">Minute: 05</option>
        <option value="10">Minute: 10</option>
        <option value="15">Minute: 15</option>
        <option value="20">Minute: 20</option>
        <option value="25">Minute: 25</option>
        <option value="30">Minute: 30</option>
        <option value="35">Minute: 35</option>
        <option value="40">Minute: 40</option>
        <option value="45">Minute: 45</option>
        <option value="50">Minute: 50</option>
        <option value="55">Minute: 55</option>
    </select>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut