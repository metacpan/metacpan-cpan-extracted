package ARS::Simple;

use 5.006;
use strict;
use warnings FATAL => 'all';
use ARS 1.68;
use Carp;
use Data::Dumper;

our $VERSION = '0.01';

$Data::Dumper::Indent=1;
$Data::Dumper::Sortkeys=1;

our %config;
my $user;
my $pword;

BEGIN
{
    my $module = 'ARS/Simple.pm';
    my $cfg = $INC{$module};
    unless ($cfg)
    {
        die "Wrong case in use statement or $module module renamed. Perl is case sensitive!!!\n";
    }
    my $compiled = !(-e $cfg); # if the module was not read from disk => the script has been "compiled"
    $cfg =~ s/\.pm$/.cfg/;
    if ($compiled or -e $cfg)
    {
        # In a Perl2Exe or PerlApp created executable or PerlCtrl
        # generated COM object or the cfg is known to exist
        eval {require $cfg};
        if ($@ and $@ !~ /Can't locate /) #' <-- syntax higlighter
        {
            carp "Error in $cfg : $@";
        }
    }
}

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    bless($self, $class);

    # Run initialisation code
    $self->_init(@_);

    return $self;
}

sub DESTROY
{
    my $self = shift;

    if ($self->{ctl})
    {
        ars_Logoff($self->{ctl});
    }
}

sub _check_initialised
{
    my $self = shift;

    unless ($self->{ctl})
    {
        $self->_carp("Connected to Remedy ARSystem has not been establised yet.\n");
        return;
    }

    return 1;
}

sub get_list
{
    my ($self, $args) = @_;  # Expect args keys of 'form', 'query', optionally 'max_returns'

    # Check ARSystem initailised
    return unless $self->_check_initialised();

    # Check required args
    unless ($args->{form} && $args->{query})
    {
        $self->_carp("get_list() requires 'form' and 'query' arguments\n");
        return;
    }


    # Create a qualifier struct
    my $qual = $self->_load_qualifier($args);
    return unless $qual;

    # Set the limit
    $self->set_max_entries($args->{max_returns});

    # Get the entryId
    my @entries = ars_GetListEntry($self->{ctl}, $args->{form}, $qual, 0, 0,
        [{columnWidth => 1, separator => ' ', fieldId => 1 }]  # Minimise the amount of data returned
        );

    # Reset the limit
    $self->_reset_max_entries();


    my @entryIds;
    # Speed hack for large retuns
    $#entryIds = $#entries;
    @entryIds = ();

    for (my $x = 0; $x < $#entries; $x += 2)
    {
        #Assign the entryId's to the array, stripping the query list values
        push @entryIds, $entries[$x];
    }
    my %results = ( numMatches => scalar(@entryIds), eids => \@entryIds );
    return \%results;
}

sub _load_qualifier
{

    my ($self, $args) = @_;

    my $qual = ars_LoadQualifier($self->{ctl}, $args->{form}, $args->{query});
    unless ($qual)
    {
        $self->_carp("_load_qualifier() Error processing query:\n$ars_errstr\n");
    }

    return $qual;
}

sub get_data_by_label
{
    my ($self, $args) = @_;

    my $form    = $args->{form};
    my $query   = $args->{query};
    my $lfid_hr = $args->{lfid};
    my @fid     = values %$lfid_hr;

    # Check ARSystem initailised
    return unless $self->_check_initialised();

    # Check required args
    unless ($args->{form} && $args->{query})
    {
        $self->_carp("get_data_by_label() requires 'form' and 'query' arguments\n");
        return;
    }

    #-- Create a qualifier struct
    my $qual = $self->_load_qualifier($args);
    return unless $qual;

    # Set the limit
    $self->set_max_entries($args->{max_returns});

    # Get the data from the form defined by qualifier qual
    my %entryList;
    if ($ARS::VERSION >= 1.8)
    {
        %entryList = ars_GetListEntryWithFields($self->{ctl}, $form, $qual, 0, 0, \@fid);
    }
    else
    {
        %entryList = ars_GetListEntryWithFields($self->{ctl}, $form, $qual, 0, \@fid);
    }

    # Reset the limit
    $self->_reset_max_entries();

    unless (%entryList)
    {
        no warnings qw(uninitialized);
        if ($ars_errstr)
        {
            $self->_carp("get_data_by_label() failed.\nError=$ars_errstr\nForm=$form\nQuery=$query\n");
        }
        else
        {
            if ($self->{log})
            {
                $self->{log}->msg(3, "get_data_by_label() no records found.\n");
            }
        }
        return;
    }

    # Map the FID's to Labels in the hashs
    my %fid2label = reverse %$lfid_hr;
    foreach my $eID (keys %entryList)
    {
        foreach my $fid (keys %{$entryList{$eID}})
        {
            if (defined $fid2label{$fid})
            {
                $entryList{$eID}{$fid2label{$fid}} = $entryList{$eID}{$fid};
                delete $entryList{$eID}{$fid};
            }
        }
    }

    return \%entryList;
}

sub get_SQL
{
    my ($self, $args) = @_;

    # Set the limit
    $self->set_max_entries($args->{max_returns});

    # Run the SQL through the ARSystem API
    my $m = ars_GetListSQL($self->{ctl}, $self->{sql});

    # Reset the limit
    $self->_reset_max_entries();

    #    $m = {
    #            "numMatches"   => integer,
    #            "rows"         => [ [r1col1, r1col2], [r2col1, r2col2] ... ],
    #         }
    if ($ars_errstr && $ars_errstr ne '')
    {
        $self->_carp('get_SQL() - ars_GetListSQL error, sql=', $self->{sql}, "\nars_errstr=$ars_errstr\n");
    }

    return $m;
}

sub set_max_entries
{
    my ($self, $max) = @_;

    if (defined $max)
    {
        # Just use the value given
    }
    elsif ($self->{max_returns})
    {
        $max = $self->{max_returns};
    }
    elsif (defined $self->{reset_limit})
    {
        $max = 0;  # Set for unlimited returns if we have a reset limit defined
    }

    if (defined $max)
    {
        unless(ars_SetServerInfo($self->{ctl}, &ARS::AR_SERVER_INFO_MAX_ENTRIES, $max))
        {
            $self->_carp("set_max_entries() - Could not set the AR_SERVER_INFO_MAX_ENTRIES to $max:\n$ars_errstr\n");
        }
    }
}

sub _reset_max_entries
{
    my $self = shift;

    if (defined $self->{reset_limit})
    {
        $self->set_max_entries($self->{reset_limit});
    }
}

sub get_fields
{
    my ($self, $form) = @_;

    # Check required args
    unless ($form)
    {
        $self->_carp("get_fields() requires the 'form' as a argument\n");
        return;
    }

    my %fids = ars_GetFieldTable($self->{ctl}, $form);
    $self->_carp("get_fields() error: $ars_errstr\n") unless (%fids);

    return \%fids;
}

sub update_record
{
    my ($self, $args) = @_;
    my $eID  = $args->{eid};
    my $form = $args->{form};
    my %lvp  = %{$args->{lvp}};


    # Map lvp to use FID rather than label
    foreach my $label (keys %lvp)
    {
        if (defined $args->{lvp}{$label})
        {
            $lvp{$args->{lfid}{$label}} = $lvp{$label};
            delete $lvp{$label};
        }
        else
        {
            carp("update_record - label '$label' not found in lfid hash");
        }
    }


    my $rv = ars_SetEntry($self->{ctl}, $form, $eID, 0, %lvp);

    # Check for errors
    unless (defined $rv && $rv == 1)
    {
        # Update failed
        my $msg = "update_record(eid=$eID, form=$form, ...) failed:\nars_errstr=$ars_errstr\nlvp data was:\n";
        foreach my $label (sort keys %{$args->{lvp}})
        {
            $msg .= sprintf("%30s (%10d) ---> %s\n", $label, $args->{lfid}{$label}, defined($lvp{$args->{lfid}{$label}}) ? $lvp{$args->{lfid}{$label}} : '<undefined>');
        }
        carp($msg);
    }
    return $rv;
}

sub get_ctl
{
    my $self = shift;

    return $self->{ctl};
}

sub _carp
{
    my $self = shift;
    my $msg = join('', @_);

    carp $msg;
    $self->{log}->exp($msg) if ($self->{log});
}

sub _init
{
    my ($self, $args) = @_;

    # Did we have any of the persistant variables passed
    my $k = '5Jv@sI9^bl@D*j5H3@:7g4H[2]d%Ks314aNuGeX;';
    if ($args->{user})
    {
        $self->{persistant}{user} = $args->{user};
    }
    else
    {
        if (defined $config{user})
        {
            my $s = pack('H*', $config{user});
            my $x = substr($k, 0, length($s));
            my $u = $s ^ $x;
            $self->{persistant}{user} = $u;
        }
        else
        {
            croak "No user defined, quitting\n";
        }
    }

    if ($args->{password})
    {
        $self->{persistant}{password} = $args->{password};
    }
    else
    {
        if (defined $config{password})
        {
            my $s = pack('H*', $config{password});
            my $x = substr($k, 0, length($s));
            my $u = $s ^ $x;
            $self->{persistant}{password} = $u;
        }
        else
        {
            croak "No password defined, quitting\n";
        }
    }
    $user  = $self->{persistant}{user};
    $pword = $self->{persistant}{password};

    # Handle the other passed arguments
    $self->{server}      = $args->{server}      if $args->{server};
    $self->{log}         = $args->{log}         if $args->{log};
    $self->{max_returns} = $args->{max_returns} if defined $args->{max_returns};
    $self->{reset_limit} = $args->{reset_limit} if defined $args->{reset_limit};

    if ($args->{ars_debug})
    {
        $ARS::DEBUGGING = 1;
    }
    $self->{debug} = $args->{debug} ? 1 : 0;

    ## Now connect to Remedy
    if ($self->{server} && $user && $pword)
    {
        my $ctl = ars_Login($self->{server}, $user, $pword);
        if ($ctl)
        {
            $self->{ctl} = $ctl;
        }
        else
        {
            croak(__PACKAGE__ . " object initialisation failed.\nFailed to log into Remedy server=" . $self->{server} . " as user '$user' with supplied password: $ars_errstr\n");
        }
    }
    else
    {
        croak(__PACKAGE__ . " object initialisation failed, server, user and password are required\n");
    }
}


    # GG test - need to find and store the current value of AR_SERVER_INFO_MAX_ENTRIES
    #           so we can set reset_limit if not defined
    #my %s = ars_GetServerInfo($self->{ctl});
    #print  Dumper(\%s);


1; # End of ARS::Simple


__END__

=head1 NAME

ARS::Simple - A simplified interface to Remedy ARSystem

=head1 SYNOPSIS

A simple interface to Remedy ARSystem utilising the ARSperl API interface.
Keeps your code more readable and by use of the cache avoids your credentials
being spread through all your scripts.

 use ARS::Simple;

 my $ar = ARS::Simple->new({
     server   => 'my_remedy_server',
     user     => 'admin',
     password => 'admin',
     });

 ### Get the Entry-ID/Request-ID for all User's with Login starting with 'g'
 # Here $eid is any array reference of entry-id/request-id values
 my $data = $ar->get_list({
     form  => 'User',
     query => qq{'Login' LIKE "g%"},
     });
 print Data::Dumper->Dump([$data], ['data']), "\n";
 # Resulting data dump:
 # $data = {
 #   'eids' => [
 #     '000000000004467',
 #     '000000000004469',
 #     '000000000004470',
 #   ],
 #   'numMatches' => 3
 #};

 ### Get data from a form, based on a query (as you would use in the User Tool)
 my $form  = 'User';
 my $entryListLabel = $ar->get_data_by_label({
     form  => $form,
     query => qq{'Login Name' LIKE "ge%"},  # Login Name = FID 101
     lfid  => { 'LoginName', 101, 'FullName', 8, 'LicenseType', 109, },
     });
 print Data::Dumper->Dump([$entryListLabel], ['entryListLabel']), "\n";
 # Resulting data dump:
 # $entryListLabel = {
 #  '000000000014467' => {
 #    'FullName' => 'Geoff Batty',
 #    'LicenseType' => 0,
 #    'LoginName' => 'gbatty'
 #  },
 #  '000000000014469' => {
 #    'FullName' => 'Greg George',
 #    'LicenseType' => 2,
 #    'LoginName' => 'gregg'
 #  },
 #  '000000000024470' => {
 #    'FullName' => 'Gabrielle Gustoff',
 #    'LicenseType' => 0,
 #    'LoginName' => 'ggustoff'
 #  },

 # Update a record, change the Login Name to 'greg'
 my %lvp = ( LoginName => 'greg' );
 $ar->update_record({
     eid  => '000000000014469',
     form => 'User',
     lvp  => \%lvp,
     lfid => { 'LoginName', 101, 'FullName', 8, 'LicenseType', 109, },
     });

=head1 VERSION

Version 0.01

=head2 FEATURES

=over 4

=item *

Provides obfuscated storage for default user and password so they are
not scattered throuhout all your scripts

=item *

Provide a perlish interface to ARSperl which makes your code
more readable

=back

=head1 METHODS

=head2 new

Constructor for ARS::Simple.  There are three required arguments:

=over 4

=item server

The name (or possibly IP Address) of the Remedy ARSystem server you
wish to connect to.

=item user

The user you wish to connect as (this is often a user with administrator
privilages).  Note that while this is a required argument, it may be supplied
via the configuration file to avoid lots of scripts with the user (and password)
in them (less to change, not on display so safer).

=item password

The password to the user you wish to connect as.  This may come from the configuration
file if set.

=back

There are a number of optional arguments, they are:

=over 4

=item max_returns

Set a limit on how many items may be returned from certain calls.
Setting this value to 0 sets unlimited returns.  This parameter
can also be set on individual calls. B<Note:> This is a system wide
configuration change and requires administrator privilages on user.

B<Note: You should not use a value less than the default system value
for this field or you may impact normal operation of your system>

Example usage:

 reset_limit => 0, # unlimited returns

=item reset_limit

Once max_returns is used, reset_limit, if set will return the server
to nominated max_returns limit (eg 3000), thereby limiting the possible
impact on the system of having max_returns set to a high value (eg 0).

Example usage:

 reset_limit => 3000, # max returns back to a suitable maximum of 3000

=item ars_debug

Turn on, if true (1), the ARSperl debugging output.
Not something you would normally use.

=item log

Pass a object to use to log erros/information to a log file.
The log object is expected to have methods I<exp> and I<msg>
as per the File::Log object.

=back

Sample invocation with ALL parameters:

 use ARS::Simple;
 use File::Log;
 my $log = File::Log->new();
 my $ars = ARS::Simple->new({
     server      => 'my_server',
     user        => 'some_admin',
     password    => 'password_for_some_admin',
     log         => $log,
     max_returns => 0,    # allow unlimited returns
     reset_limit => 3000, # reset to a suitable limit after each call using max_returns
     ars_debug   => 1,    # get a whole lot of debugging information (you real should not need)
     });

=head2 get_list

Method to return an array reference of Entry-Id values for a form.
Arguments are passed as an hash reference, with two required parameters, eg:

 # Get theEntry-Id's for all records in the 'User' form.
 my $eids = $ars->get_list({ form => 'User', query => '1 = 1' });

The query parameter can be the same format as you would use in the 'User Tool'
to query a form, however we recommend the use of field ID's (FID) rather than the
default field name as they may change.  I prefer to define a hash of the
forms lables and FID's so that can be used to better document your code, eg

 my %user = ( UserID => 101, UserName => 102 );

the a query could be something like

 my $query = qq{ '$user{UserID}' LIKE "g%" };
 my $eids = $ars->get_list({ form => 'User', query => $query });

=head2 get_data_by_label

Query a form and get the data back as a hash reference where the
keys are the Entry-Id's for the records matched by the query and
the value is a hash reference to the fields you requested where
the keys are the field names you used and the value are the values.

 my $form  = 'form';
 my $query = qq('FID' = "value");
 my $data = $ar->get_data_by_label({
     form  => $form,
     query => $query,
     lfid  => { label1, fid1, label2, fid2, ...},
     });

 $data = {
     eID1, {Label1 => value1, Label2 => value2, ...},
     eID2, {Label1 => value1, Label2 => value2, ...},
     ...
     };

=head2 update_record

Update a record on a form based on the Entry-Id (eid).  The
data to update is defined in the lvp (label value pair) hash reference.
The other required argument is the lfid (label FID) hash reference which
is used to map the labels to field Ids (FID).

The method returns true on success and carps on error.

update_record({
    eid  => $eID,           # The Entry-Id/Request-Id to update
    form => $form,          # The form to update
    lvp  => \%lvp,          # The data to be updated as a label => value hash ref
    lfid => \%labelFIDhash  # The label FID hash reference
    });

=head2 get_SQL

Run direct SQL on your server, there is only one required argument,
the sql, you may optionally set the max_returns value.

The names of the fields can be found from the Admin Tool, under
the database tab for a form.  This will be the name of the field
used in the database view of the Remedy form. B<Note> you do need
to replace spaces with and underscore '_' character.

Example method call:

 my $data = $ars->get_SQL({
     sql => q{select Login_name, Full_Name from User_X where Login_name like 'g%' order by Login_name},
     max_returns => 0,
     });

The return is a hash reference with two keys, numMatches and rows, example:

 $data = {
     numMatches = > 2,
     rows => [
        'greg', 'Greg George',
        'geoff', 'Geoffery Wallace',
     ]
 };

=head2 get_ctl

Returns the ARSystem control structure, so you can use it in other
ARSperl calls.

=head2 get_fields

get_fields has a required argument, the form you require the
field details for.  The returned hash reference is the result
of a call to ars_GetFieldTable, the keys are the field names
and the values are the field ids (fid).

=head2 set_max_entries

This requires that the 'user' has administrator access.  This
allows the overriding of the B<system wide> maximum rows returned
setting AR_SERVER_INFO_MAX_ENTRIES, setting this to zero (0) will
allow unlimited returns.

B<Beware of setting this to a small value, it is system wide and
could have a major impact on your system>

=head1 PRIVATE METHODS

=head2 _init

Initialisation for new and handling of cache

=head2 _load_qualifier

Convert a query to a qualifier structure

=head2 _check_initialised

Check to insure that there is a connection to Remedy ARSystem.
Returns true if connected.

=head2 _reset_max_entries

If set, returns the the system wide AR_SERVER_INFO_MAX_ENTRIES back
to a suitable value (eg 3000).  This required the 'user' has administrator
access

=head2 _carp

Complain if something went wrong & possible add to the log file

=head2 DESTROY

Log out from ARSystem

=head1 ARSperl Programer's Manual

see http://arsperl.sourceforge.net/manual/toc.html

=head1 Default User/Password

The default user and password to use can be configured during install
by the Config.PL script.  This creates a configuration file Simple.cfg
which is stored with Simple.pm.  Unless specified in the call to the
new method, the use and password from Simple.cfg will be used.  This
has the advantage of a single place of change and removes the user and
password from scripts.

Note that the use and password are obfuscated and B<not> encrypted in
the Simple.cfg file.

=head1 TODO

Add in the tools below.

Add in further methods to make life easier and your code more readable

=head1 TOOLS

B<NOT DONE YET>

The lfid array used by the get_data_by_label() method
required that a hash is defined which describes the
field lables (names) you want to use mapped to the
field ID (FID).  The encluded script will construct
such a hash for all relavent fields.  You might like
to edit this down to only those fields you really need
thereby reducing the amount of data returned.

There is a win32 version of this which copies the data
to your clipboard, to make your life easier.

=head1 AUTHOR

Greg George, C<< <gng at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ars-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ARS-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ARS::Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ARS-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ARS-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ARS-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/ARS-Simple/>

=back

=head1 ACKNOWLEDGEMENTS

This module relies on the ARSperl module and the fantastic effort
by Jeff.C.Murphy and Joel.W.Murphy to write keep ARSperl current over
so many years (along with Bill Middleton & G. David Frye).

 See http://arsperl.sourceforge.net/ for more details.
 and https://metacpan.org/release/ARSperl

Remedy Corporation (long since gone) for making the ARSystem
C API available thereby allowing ARSperl and this module possible

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Greg George.

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
