package DBIx::Repgen;

use 5.006;
use strict;
use Carp;
our $VERSION = '0.01';


##############################################################################################
##############################################################################################
##############################################################################################

=head1 NAME

DBIx::Repgen - simple report generator from DB-selected data

=head1 SYNOPSIS

 use Repgen;

 $r = DBIx::Repgen->new(
		 dbh => DBI->connect(...),
		 query => 'select ... from ...',

		 repdata => {
			     today => `date`
			    },

		 group => ['id'],
		 header => "========\n",
		 footer => sub {my ($r, $data) = @_; return "$data->{NAME} : $data->{VALUE}"},
		 item => ["%20s %s", qw/NAME VALUE/],

		 output => \$out;
		);

 $r->run(cust => 'tolik');
 print $out;

=head1 DESCRIPTION

This package implements class C<DBIx::Repgen>, which is simple report generator from data
received from relational database by some select-statement. Such a report can contain
hyerarchical grouping by field values, record counters and cumulative totals (sums) of numeric
fields for each group as well as for whole report. Each rerort part formatting may be set
as literal string, arguments of C<sprint> function or be code reference.

=head2 new, class constructor

Constructor has one argument, hashe. Elements of this hashe define the report and are
descriebed below.

=over

=item sth, dbh, query - data source setting

The report data are got by executing some select statement against relational database
environment. There are following wais for defining this statement.

=over

=item 1.

Constructor receives in C<sth> element prepared (C<$dbh->prepare>) but not executed
(C<$sth->execute>) statement handle.

=item 2.

Constructor receives database connection handle (from C<DBI->connect(...)>) and full text
of select statement to be executed. Needed C<prepare> and C<execute> calls will perform
by the report run.

=item 3.

Constructor receives already prepared and executed statement handle. In this case C<noexec>
constructor parameter must be set to true. This feature may be useful by dynamic-made select
queryes in calling programm. No prepare nor execute action will be performed by report run.

I<Important note>: you have to reset (by C<Set> method) this statemeny handle before each next
report run.

=back

 Samples:

 $dbh = DBI->connect('dbi:Oracle:SID', 'user', 'password');
 $sth1 = $dbh->prepare('select name, value from tab where value between ? and ?');
 $rep1 = DBIx::Repgen->new(sth => $sth);

 $rep2 = DBIx::Repgen->new(dbh => $dbh, query => "select ... ");

 $sth3 = $dbh->prepare('select ...');
 $sth3->execute(@param);
 $rep3 = DBIx::Repgen->new(sth => $sth3, noexec => 1);

Using first two methods you may parametrize the report. This means sql-query can contain
placeholders, for substituting values in report run time. See below about report parameters.

=item param - report parameters

The report may have set of named parameters. Single parameter definition contain its name,
number (or some numbers) of placeholders in source select query and optional default value.
Parametrs definition is a hash reference, value of C<param> element of constructor. Keys in this
hash are parameter names and values contain placeholder numbers and default values.

In the simpliest case parameter definition can be just zero-based number of the only placeholder
corresponding to this parameter. In more complex cases is is hash reference. This hash I<must>
have C<n> key with value of integer or list of integers and I<may> have C<dflt> key, which
value must be scalar, code reference or array reference (where first element is code reference).

The C<n> key defines zero based number (or numbers) of placeholdes in source select query
corresponding to this parameter. The C<dflt> key defines default value for optional
parameters. If value of C<dflt> is code reference then default value is result of this code call (without
arguments). If value of C<dflt> is array reference then first element of this array must
be code reference. Default value of parameter in this case is result of call this code with arguments -
the rest of array.

Sample of parameter definition.

  $rep = DBIx::Repgen->new(
    ...
    param => {
      name => 0,
      dep => {n => 1},
      startdate => {n => [2, 4], dflt => '2000/01/01'},
      enddate => {n => 3, dflt => \&DefEndDate},
      salary => {n => 5, dflt => [sub {...}, 1000, 2000]}
    }
  );

In the example C<name> and C<dep> are required parameters corresponding to zero and first placeholders.
C<startdate> has explicit default value and substituted to second and fouth placeholders.
C<enddate> and C<salary> have defaults defining by code call in report run time, without and
with arguments in correspondence.


=item output - the way of report output

The C<output> constructor's parameter sets how and where the report puts its output data.

=over

=item undef or not present

The whole output data are the result of C<run> method call.

=item string reference

The output data are put into this string.

=item code reference

This code will be called with two arguments: the report object and string to be out.

=back

Output samples.

 $r = DBIx::Repgen(...);
 print $r->run();

 $s = '';
 $r = DBIx::Repgen(..., output => \$s,);
 $r->run();
 print $s;

 sub myprint {
   my ($r, $s) = @_;
   print "*** $s ***";
 }
 $r = DBIx::Repgen(..., output => \&myprint,);
 $r->run();

=item group - repport groupping

The report may be I<groupped>. The group is sequence of records having the constant value of some
field. This field called I<group field>. The report may have several includded groups. For
group setting you have to define C<group> parameter of report constructor as a reference to
an array of group fields.

Note that the right record's sequence must be provided by C<order> part in used select query, not
by report itself. Sample of grouping by countries and cities.

 $r = DBIx::Repgen->new(
   ...,
   query => "select country, city, population from cities
             order by country, city",
   group => [qw/COUNTRY CITY/],
   ...
 );

Note I<all> field names are in uppercase, regardless used database server.

=item total - cumulative totals

Value of this argument of constructor is reference to array with report fields to compute
totals. Each field summation executed for all the report as well as for each group. See
below about access to totals values.

=item header, footer, item etc. - definition of report parts

There are following I<parts> generated during report output.

=over

=item item

Outputs for each record of the report.

=item header

Begin of whole report.

=item footer

Outputs after all, in the very end of report.

=item header_GROUPFIELD

Outputs in the begin of record group by GROUPFIELD field.

=item footer_GROUPFIELD

Outputs after record group by GROUPFIELD field.

=back

Each of these report pats may be defined by several ways.

=over

=item string

The string will be printed "as is", without any processing.

 $r = DBIx::Repgen->new(
   header => "\t\tReport about countries and cities\n",
   ...
 );


=item reference to array of strings

First element of this array have to be in form of C<sprintf> function format. The rest
of values in the array are I<names> (not values!) of current report data. See below
about current report data.

 $r = DBIx::Repgen->new(
   footer => ["Total %d countries, %d cities, population %d people\n",
              qw/num_COUNTRY num_CITY sum_POPULATION/],
   ...
 );

=item code reference

The code is called with two arguments: report object and hash reference storing
current report data. Subroutine may use C<Output> method for output any needed
information or just return output string as its result.

 $r = DBIx::Repgen->new(
   item => sub {
     my ($r, $d) = @_;
     $r->Output("%d %s",
                $d->{POPULATION},
                $d->{POPULATION} > 1_000_000 ? '*' : ' ');
   }

   footer => sub {return "Report ended at " . `date`}
   ...
 );

=item reference to array where first element is code reference

The code is called with following arguments: report object, current report data, the rest of
array elements.

 $r = DBIx::Repgen->new(
   header_COUNTRY => [\&hfcountry, 'header'],
   header_COUNTRY => [\&hfcountry, 'footer'],
   ...
 );

 sub hfcountry {
  my ($r, $d, $header_or_footer) = @_;
  if ($header_or_footer eq 'header') {...} else {...};
 }

=item max_items - max record number limit

If this parameter (integer number) is present then no more than C<max_items> records will be
output. It is possible to know via C<Aborted> method call if not all records were output.

=back

=head3 Current report data

All report state data are stored in internal report variables. Access to these data from
report parts is possible by data names. There are following fields in current
report data.

=over

=item FIELDNAME

Fields of current report's record. Name is in I<uppercase>.

=item prev_FIELDNAME

Value of FIELDNAME in previous record. When group boundary is detected group field has new value,
but its previous value is still stored. This value can be used in group footers.

=item num_report

Number (one-based) of current output record for the whole report. This counter never resets.

=item num_item

Number of record in the innermost group.

=item num_GROUPNAME

Number of group GROUPNAME in including group.

=item total_FIELDNAME

Cumulative total of FIELDNAME field for the whole report. Remember FIELDNAME must be listed
in C<total> constructor's parameter.

=item total_GROUPNAME_FIELDNAME

Cumulative total by FIELDNAME field into GROUPNAME. These summators are reset each time
the group boundary is reached.

=back


=back


=cut


use strict;

sub new {
  my ($class, %par) = @_;

  return bless \%par, ($class || ref $class);
}

=head2 run, report execution

 $r->run(%param);

The report is run and output. Input parameters are substituted as values for select query
placeholders (see above about report's parameters). If there was no C<output> constructor's parameter
then the text of report returned as a result of this method.

=cut

sub run {
  my ($rep, %param) = @_;

  my $warn = $^W;
  $^W = 0;

  unless ($rep->{sth}) {
    croak "Missing 'dbh' arg" unless exists $rep->{dbh};
    croak "Missing or non-select query" unless $rep->{query} && $rep->{query} =~ /^\s*select\b/si;
    $rep->{sth} = $rep->{dbh}->prepare($rep->{query});
  }

  unless ($rep->{output}) {
    $rep->{outputstr} = '';
    $rep->{output} = \$rep->{outputstr};
  }

  delete $rep->{not_first};

  $rep->{data} = {num_report => 0, num_item => 0};

  $rep->{param} = {} unless exists $rep->{param};
  my @param = ();
  goto AFTEREXEC if $rep->{noexec};
  for my $p (keys %{$rep->{param}}) {
    $rep->{param}{$p} = {n => $rep->{param}{$p}}
      unless ref($rep->{param}{$p});
    croak "No positions are given for '$p' parameter" unless exists $rep->{param}{$p}{n};

    my @n;
    if (ref ($rep->{param}{$p}{n}) eq 'ARRAY') {
      @n = @{$rep->{param}{$p}{n}};
    } elsif (!ref($rep->{param}{$p}{n})) {
      @n = ($rep->{param}{$p}{n});
    } else {
      croak "Non scalar nor array reference positions for '$p' parameter";
    }

    my $val;
    if (defined($param{$p}) && $param{$p} ne '') {
      $val = $param{$p};
    } elsif (defined $rep->{param}{$p}{dflt}) {
      $val = $rep->{param}{$p}{dflt};
      unless (ref $val) {
	# nothing
      } elsif (ref($val) eq 'CODE') {
	$val = $val->();
      } elsif (ref($val) eq 'ARRAY' && $val->[0] && (ref($val->[0]) eq 'CODE')) {
	my ($sub, @pars) = @$val;
	$val = $sub->(@pars);
      } else {
	croak "Wrong dflt for '$p' parameter";
      }
    } else {
      croak "Cannot determine value for parameter '$p'";
    }
    $param[$_] = $val for grep {$_ >= 0} @n;
    $rep->{data}{"param_$p"} = $val;
  }
  $rep->{sth}->execute(@param);
 AFTEREXEC:


  # Заголовок отчета
  $rep->PrintPart('header');

  # строки отчета
  while ($rep->{row} = $rep->{sth}->fetchrow_hashref('NAME_uc')) {
    $rep->PrintItem();
    $rep->Abort() if $rep->{max_items} && $rep->{max_items} <= $rep->{data}{num_report};
    last if $rep->Aborted();
  }
  $rep->{sth}->finish();

  # Если надо - завершители групп после отчета
  if (exists $rep->{group}) {
    # Формируем "пустую" строку
    for (keys %{$rep->{data}}) {
      $rep->{row}{$1} = undef if /prev_(.+)/;
    }
    $rep->PrintHeaderFooter(0, 'footer');
  }

  # Завершитель отчета
  $rep->PrintPart('footer');

  $^W = $warn;

  # Закрыть коннекцию если надо
  $rep->{dbh}->disconnect() if $rep->{dbh} && $rep->{autoclose};

  return $rep->{outputstr};
}

sub PrintItem {
  my ($r) = @_;

  # Скопировать поля строки в data
  $r->{data}{$_} = $r->{row}{$_} for keys %{$r->{row}};

  # Продвинуть "сквозные" сумматоры по полям
  if (exists $r->{total}) {
    $r->{data}{'total_' . $_} += $r->{row}{$_} for @{$r->{total}};
  }

  # Есть ли граница группы?
  my $group = $r->GroupGranze();

  # Если это не самый первый раз - вывести завершители групп
  $r->PrintHeaderFooter($group, 'footer')
    if defined $group && $r->{not_first};

  # Установить, что уже - не первый раз
  $r->{not_first} = 1;

  # Продвинуть сквозной номер и номер в пределах младшей группы
  $r->{data}{num_report} ++;
  $r->{data}{num_item} ++;

  # Вывести заголовок группы (при этом сбрасываются сумматоры и нумераторы)
  $r->PrintHeaderFooter($group, 'header') if defined $group;

  # Просуммировть групповые сумматоры
  if ($r->{group} && $r->{total}) {
    for my $grname (@{$r->{group}}) {
      $r->{data}{'total_' . $grname . '_' . $_} += $r->{row}{$_} for @{$r->{total}};
    }
  }

  # Вывести итем
  $r->PrintPart('item');

  # Записать в $data предыдущие значения строки
  $r->{data}{'prev_' . $_} = $r->{row}{$_} for keys %{$r->{row}};

  1;
}

sub PrintHeaderFooter {
  my ($r, $group, $hf) = @_;
  my @group = @{$r->{group}};

  # Если заголовок
  if ($hf eq 'header') {
    # Сбросить сумматоры для каждой группы старше указанной
    if ($r->{total}) {
      for my $grname ((@group)[$group .. $#group]) {
	$r->{data}{'total_' . $grname . '_' . $_} = 0 for @{$r->{total}};
      }
    }

    # И нумераторы
    $r->{data}{'num_' . $r->{group}[$group]}++;
    $r->{data}{'num_' . $_} = 1 for (@group)[$group+1 .. $#group];
    $r->{data}{'num_item'} = 1;
  }

  # Таки напечатать заголовки или завершители
  $r->PrintPart($hf . '_' . $_) for (@group)[$group .. $#group];
}

sub GroupGranze {
 my ($r) = @_;

 return undef unless $r->{group};

 my $i = 0;
 for my $fname (@{$r->{group}}) {
   croak "No '$fname' group field in data" unless exists $r->{row}{$fname};

   return $i if
     !exists($r->{data}{'prev_' . $fname}) ||
       (
	(($r->{data}{'prev_' . $fname} ne $r->{row}{$fname})) ||
	(($r->{data}{'prev_' . $fname} != $r->{row}{$fname}))
       );
   $i++;
 }

 undef;
}


sub PrintPart {
  my ($r, $part) = @_;

  return unless $r->{$part};

  my ($fmt, @par);
  if (ref($r->{$part}) eq 'ARRAY') {
    ($fmt, @par) = @{$r->{$part}};
  } elsif (ref($r->{$part}) eq 'CODE' || !ref($r->{$part})) {
    ($fmt, @par) = ($r->{$part});
  } else {
    croak sprintf("Non supported type of format: '%s'", ref($r->{$part}));
  }

  my $s;
  if (ref $fmt) {
    $s = $fmt->($r, $r->{data}, @par);
  } else {
    $s = sprintf($fmt, map {$r->{data}{$_}} @par);
  }

  $r->Output($s);
}

=head2 Output

 $r->Output("Any values: %s and %d", 'qazwsx', 654);

This method has the same arguments as C<sprintf> function. It adds formatted string to the output
stream (set by C<output> param). This method is useful in the code called during the output of
report parts.

=cut

sub Output {
  my ($r, $s, @par) = @_;

  $s = sprintf($s, @par) if @par;

  if (ref($r->{output}) eq 'CODE') {
    $r->{output}->($r, $s);
  } elsif (ref($r->{output}) eq 'SCALAR') {
    ${$r->{output}} .= $s;
  } else {
    croak "Non supported output method";
  }
}

=head2 Get, querying of report parameters

  @group = @{$r->Get('group')};

Method returns value of named parameter which is set in constructor or via C<Set> method.

=cut

sub Get {
  my ($r, $name) = @_;
  return $r->{$name};
}

=head2 Set, setting report parameters

 $r->Set(
   header => "Very new header",
   item => ["%s %s", qw/NAME VALUE/]
 );

Method redefines report parameters.

=cut

sub Set {
  my ($r, %set) = @_;
  while (my ($k, $v) = each %set) {
    $r->{$k} = $v;
  }
}

=head2 Abort

 $r->Abort();

Being called in the code it breaks report running.

=cut

sub Abort {$_[0]->{aborted} = 1}

=head2 Aborted

  if ($r->Aborted()) {...}

Method returns true if report execution was aborted by C<Abort> method.

=cut

sub Aborted {$_[0]->{aborted}}

1;

__END__

=head1 EXAMPLE

Full example of report and its result. The data are taken from data table having following
structure.

 create table population (
  country varchar2(30) not null,
  city varchar2(30) not null,
  population int not null
 );

Full text of the perl script and output data are following. These are just demo data!

 #!/usr/bin/perl -w

 use strict;
 use DBI;
 use DBIx::Repgen;

 my $dbh = DBI->connect('dbi:Oracle:SID',
                    'user', 'password') or die $@;
 my $sth = $dbh->prepare(<<EOM);
 select
  country,
  city,
  population
 from
  population
 order by
  country,
  city
 EOM

 my $r = DBIx::Repgen->new
  (
   sth => $sth,
   group => [qw/COUNTRY/],
   total => [qw/POPULATION/],

   header => [\&makeheader,
              '=', "Countries, cities and thier population"],
   footer => ["Total %d countries, %d cities, %d people\n",
              qw/num_COUNTRY num_report total_POPULATION/],

   header_COUNTRY => sub {
     my (undef, $d) = @_;
     return makeheader(undef, undef, '-', $d->{COUNTRY});
   },
   footer_COUNTRY => ["%d cities, %d people in %s\n\n",
          qw/num_item total_COUNTRY_POPULATION prev_COUNTRY/],

   item => ["\t\t%-20s %10d\n", qw/CITY POPULATION/],
  );

 print $r->run();

 sub makeheader {
  my (undef, undef, $c, $s) = @_;
  return sprintf("%s\n%s\n%s\n", $c x length($s), $s, $c x length($s));
 }

 ======================================
 Countries, cities and thier population
 ======================================
 ---------
 Australia
 ---------
		Kanberra                 900000
		Sidney                  6400000
 2 cities, 7300000 people in Australia

 ------
 Russia
 ------
		Moscow                  9500000
		Rostov-on-Don           1200000
		St.Petersberg           4500000
		Taganrog                 250000
 4 cities, 15450000 people in Russia

 ---
 USA
 ---
		Los Angeles             4000000
		New York               12000000
		Washington              2000000
 3 cities, 18000000 people in USA

 Total 3 countries, 9 cities, 40750000 people

=cut

