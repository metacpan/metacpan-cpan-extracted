##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************
package App::GnuCash::MembershipUtils;

use strict;
use warnings;
use YAML::XS;
use GnuCash::Schema;
use DBD::SQLite;
use Exporter qw( import );
use File::Slurp;
use Data::Dump qw( pp );
use Readonly;
use Carp qw( carp );

our @EXPORT_OK = qw(
    db_accounts_to_hash
    get_all_members
    get_config
    get_gnucash_filename
    max_length
    open_gnucash
    title_case
    validate_accounts_in_config
);

our %EXPORT_TAGS = (
    all    => [ @EXPORT_OK ],
    config => [ qw(
        get_config
        get_gnucash_filename
        validate_accounts_in_config
    )],
    db     => [ qw(
        db_accounts_to_hash
        get_all_members
        open_gnucash
    )],
    other  => [qw(
        max_length
        title_case
    )],
);


Readonly::Scalar my $EXPECTED_INVOICE_ACCOUNT_TYPE => "RECEIVABLE";
Readonly::Scalar my $EXPECTED_ITEM_ACCOUNT_TYPE    => "INCOME";


Readonly::Hash my %DEFAULT_CONFIG_VALUES => (
    format => "us",
    memo   => "Monthly membership dues",
);

## Version string
our $VERSION = qq{0.01};

=head1 NAME

App::GnuCash::MembershipUtils - A group of perl modules and scripts to help in
using L<GnuCash|https://www.gnucash.org/> for membership.

=head1 DESCRIPTION

App::GnuCash::MembershipUtils is a group of perl modules and scripts to help in
using L<GnuCash|https://www.gnucash.org/> for membership.

It assumes all customers are members, and uses the customer "notes" field to 
determine what type of membership for each member / customer.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use App::GnuCash::MembershipUtils qw( :all );


=cut

=head1 PUBLIC FUNCTIONS

=cut

=head2 get_config($filename)

    my ($error, $config) = get_config($filename);

Returns an C<$error> if the given C<$filename> cannot be opened.
If there is no C<$error> then C<$config> will be a HASHREF with the
config.

=cut

sub get_config {
    my $filename = shift // "";
    my $debug    = shift // 0;
    $filename    =~ s/^\s+|\s+$//g;

    return ("filename cannot be empty", undef) unless length($filename);

    return ("filename '$filename' does not exist", undef) unless -f $filename;

    $YAML::XS::ForbidDuplicateKeys = 1;
    my $config = Load(scalar(read_file($filename)));
    my @errors;

    # Now we have a hash, let's make sure it has what we need
    if (exists($config->{MembershipTypes})) {
        if (exists($config->{MembershipTypes}{default})) {
            my $error = _validate_membership_type_config($config->{MembershipTypes}{default}, 1);
            if ($error) {
                push(@errors, "The 'MembershipTypes.default' section $error"); 
            }
            if (my $others = $config->{MembershipTypes}{others}) {
                 my $idx;
                 for my $type (@$others) {
                    $idx++;
                    if (my $error = _validate_membership_type_config($type)) {
                        push(@errors, "The 'MembershipTypes.others' entry $idx $error"); 
                    }
                 }
            }
        } else {
            push(@errors, "Missing 'MembershipTypes.default' section");
        }
    } else {
        push(@errors, "Missing 'MembershipTypes' section");
    }
    if (@errors) {
        my $error = sprintf(
            "The config has the following %s\n  * %s",
            ((scalar(@errors) == 1) ? "error" : "errors"),
            join("\n  * ", @errors),
        );
        return ($error, $config);
    }
    if ($debug) {
        printf STDERR "Before applying defaults\n%s\n", pp( $config );
    }

    ## Load defaults
    for my $key (keys %DEFAULT_CONFIG_VALUES) {
        ## Only load them if the current key is undefined
        $config->{GnuCash}{$key} //= $DEFAULT_CONFIG_VALUES{$key};    
    }
    
    if ($debug) {
        printf STDERR "After applying defaults\n%s\n", pp( $config );
    }

    return (undef, $config);
}

=head2 get_gnucash_filename($override, $config)

    my $filename = get_filename_from_config($override, $config);

Returns the C<GnuCash.file> from the given C<$config>.

=cut

sub get_gnucash_filename {
    my $override = shift // "";
    my $config   = shift // {};

    return $override if length($override);
    if (exists($config->{GnuCash})) {
        return $config->{GnuCash}{file} // "";
    }
    return "";
}

=head2 open_gnucash($filename)

    my ($error, $schema) = open_gnucash($filename);

Returns an C<$error> if the given C<$filename> cannot be opened.
If C<$error> is undef, then C<$schema> will be a C<GnuCash::Schema>
object.

=cut

sub open_gnucash {
    my $filename = shift // "";

    return ("filename '$filename' does not exist", undef) unless -f $filename;

    my $schema = GnuCash::Schema->connect(
        "dbi:SQLite:$filename",     # dsn
        undef,                      # user
        undef,                      # password
        {                           # dbi params
            sqlite_open_flags => DBD::SQLite::OPEN_READONLY,
        }
    );

    return (undef, $schema);
}

=head2 get_all_members($args)

    my @members = get_all_members($args);


Accepts a HASHREF of C<$args> whose keys are as follows:

=over

=item config

=item schema

=item active_only

=back

Returns an ARRAY of HASHREFs whose keys are as follows:

=over

=item name

=item id

=item notes

=item active

=item membership_type

=item membership_account

=item membership_amount

=back

=cut

sub get_all_members {
    my $args = shift;

    my $active_only = delete $args->{active_only};
    my $schema      = delete $args->{schema};
    my $config      = delete $args->{config};
    my $debug       = delete $args->{debug} // 0;
    if (my @unused = sort(keys(%$args))) {
        carp(
            sprintf(
                "WARNING: The following unused %s provided: '%s'",
                (scalar(@unused) == 1 ? "parameter was" : "parameters were"),
                join("', '", @unused),
            )
        );
    }

    # Get default type from config
    my $default_type = {
        map { $_ => $config->{MembershipTypes}{default}{$_} } qw( account amount name )
    };

    # Get the other types from the config
    my @types;
    for my $type_config (@{$config->{MembershipTypes}{others}}) {
        my $type = {
            map { $_ => $type_config->{$_} } qw( account amount match name )
        };
        push(@types, $type);
    }

    my @results;
    my $rs = (
        $active_only
        ? $schema->resultset('Customer')->active_customers({ columns => [qw( id name notes active )], })
        : $schema->resultset('Customer')->all_customers({ columns => [qw( id name notes active )], })
    );

    while (my $db_member = $rs->next) {
        my $member = { $db_member->get_columns };
        printf("Processing '%s' - '%s' \n", $member->{name}, $member->{notes}) if $debug;
        MATCH_LOOP: for my $idx (0 .. $#types) {
            printf("  Matching against '%s' ... ", $types[$idx]->{match}) if $debug;
            if ($member->{notes} =~ m/\Q$types[$idx]->{match}/) {
                print "MATCH\n" if $debug;
                $member->{membership_type}    = $types[$idx]->{name};
                $member->{membership_amount}  = $types[$idx]->{amount};
                $member->{membership_account} = $types[$idx]->{account};
                last MATCH_LOOP;
            } else {
                print "NO MATCH\n" if $debug;
            }
        }
        unless ($member->{membership_type}) {
            $member->{membership_type}    = $default_type->{name};
            $member->{membership_amount}  = $default_type->{amount};
            $member->{membership_account} = $default_type->{account};
        }
        print( pp( $member ), "\n") if $debug;
        push(@results, $member);
    }

    return (@results);

}

=head2 title_case($string)

    my $title = title_case($string);

Converts the given C<$string> by returning a string by converting
the snake case into title case.

=cut

sub title_case {
    my $string = shift // "";

    my @parts = split("_", $string);
    return join(" ", map { ucfirst($_) } @parts);
}

=head2 max_length(@strings)

    my $max = max_length(@array);

Returns the maximum length of the strings in the arguments provided.

=cut

sub max_length {
    my @strings = @_;

    my $max = 0;

    for my $string (@strings) {
        my $len = length($string);

        $max = $len if ($len > $max);
    }

    return $max;
}

=head2 db_accounts_to_hash($schema)

    my $accounts = db_accounts_to_hash($schema);

Returns a HASHREF whose keys are the complete name of each
account, and whose keys are as follows:

=over

=item account_type

=item hidden

=item placeholder

=back

=cut

sub db_accounts_to_hash {
    my $schema = shift;
    my %accounts;

    my $rs = $schema->resultset('Account')->search(
        {
            # parent_guid IS NOT NULL
            parent_guid => { '!=' => undef, },           
        },
        {
            columns => [qw( name account_type hidden placeholder guid parent_guid )],
        }
    );

    while (my $account = $rs->next) {
        my $full_name = $account->complete_name;
        $accounts{$full_name} = { $account->get_columns };
    }

    return \%accounts;
}

=head2 validate_accounts_in_config($args)

    my ($errors, $warnings) = validate_accounts_in_config($args);
    warn $warnings if ($warnings);
    die $errors if ($errors);

Accepts a HASHREF of C<$args> whose keys are as follows:

=over

=item config

=item schema

=back

Returns C<$errors> which is a string indicating fatal errors, and
C<$warnings> which is a non-fatal error.

=cut

sub validate_accounts_in_config {
    my $args   = shift;
    my $schema = delete $args->{schema};
    my $config = delete $args->{config};
    my $debug  = delete $args->{debug} // 0;

    my $accounts = db_accounts_to_hash($schema);
    my @errors;
    my @warnings;
    if (exists($config->{GnuCash})) {
        my $config_account = $config->{GnuCash}{account};
        if (my $gc_account = $accounts->{$config_account}) {
            if ($gc_account->{account_type} ne $EXPECTED_INVOICE_ACCOUNT_TYPE) {
                _warning_account_type(
                    \@warnings,
                    "'GnuCash.account'",
                    $gc_account,
                    $EXPECTED_INVOICE_ACCOUNT_TYPE,
                );
            } elsif ($gc_account->{hidden} || $gc_account->{placeholder}) {
                _error_hidden_or_placeholder_account(
                    \@errors,
                    "'GnuCash.account'",
                );
            }
        } else {
            _error_invalid_account(\@errors, "'GnuCash.account'");
        }
    } else {
        push(@errors, "Missing 'GnuCash' section");
    }
    if (exists($config->{MembershipTypes})) {
        if (exists($config->{MembershipTypes}{default})) {
            my $error = _validate_membership_type_config($config->{MembershipTypes}{default}, 1);
            if ($error) {
                push(@errors, "The 'MembershipTypes.default' section $error"); 
            } else {
                my $config_account = $config->{MembershipTypes}{default}{account};
                if (my $gc_account = $accounts->{$config_account}) {
                    if ($gc_account->{account_type} ne $EXPECTED_ITEM_ACCOUNT_TYPE) {
                        _warning_account_type(
                            \@warnings,
                            "'MembershipTypes.default.account'",
                            $gc_account,,
                            $EXPECTED_ITEM_ACCOUNT_TYPE,
                        );
                    } elsif ($gc_account->{hidden} || $gc_account->{placeholder}) {
                        _error_hidden_or_placeholder_account(
                            \@errors,
                            "'MembershipTypes.default'",
                        );
                    }
                } else {
                    _error_invalid_account(\@errors, "'MembershipTypes.default'");
                }
            }
            if (my $others = $config->{MembershipTypes}{others}) {
                 my $idx;
                 for my $type (@$others) {
                    $idx++;
                    my $section = "'MembershipTypes.others' entry $idx";
                    my $config_account = $type->{account};
                    if (my $gc_account = $accounts->{$config_account}) {
                        if ($gc_account->{account_type} ne $EXPECTED_ITEM_ACCOUNT_TYPE) {
                            _warning_account_type(
                                \@warnings,
                                $section,
                                $gc_account,
                                $EXPECTED_ITEM_ACCOUNT_TYPE,
                            );
                        } elsif ($gc_account->{hidden} || $gc_account->{placeholder}) {
                            _error_hidden_or_placeholder_account(
                                \@errors,
                                $section,
                            );
                        }
                    } else {
                        _error_invalid_account(\@errors, $section);
                    }
                 }
            }
        } else {
            push(@errors, "Missing 'MembershipTypes.default' section");
        }
    } else {
        push(@errors, "Missing 'MembershipTypes' section");
    }
    my $error_string;
    if (@errors) {
        $error_string = sprintf(
            "The config has the following fatal %s\n  * %s",
            ((scalar(@errors) == 1) ? "error" : "errors"),
            join("\n  * ", @errors),
        );
    }
    my $warning_string;
    if (@warnings) {
        $warning_string = sprintf(
            "The config has the following non-fatal %s\n  * %s",
            ((scalar(@warnings) == 1) ? "error" : "errors"),
            join("\n  * ", @warnings),
        );
    }

    return ($error_string, $warning_string);
}

sub _warning_account_type {
    my $warnings = shift;
    my $section  = shift;
    my $account  = shift;
    my $type     = shift;

    push(
        @$warnings, 
        sprintf(
            "The %s account type is '%s' but should be '%s'",
            $section,
            $account->{account_type},
            $type,
        )
    );
}

sub _error_hidden_or_placeholder_account {
    my $errors  = shift;
    my $section = shift;
    push(
        @$errors, 
        sprintf(
            "The %s account cannot be hidden, or a placeholder.",
            $section,
        )
    );
}
sub _error_invalid_account {
    my $errors  = shift;
    my $section = shift;

    push(
        @$errors, 
        sprintf(
            "The %s account could not be found.",
            $section,
        )
    );
}

sub _validate_membership_type_config {
    my $config        = shift // {};
    my $default_type  = shift // 0;
    my @required_keys = qw( account amount name );
    push(@required_keys, qw( match )) unless $default_type;
    my @missing;
    my $invalid_amount;

    for my $key (@required_keys) {
        if (exists($config->{$key}) && defined($config->{$key})) {
            if ($key eq 'amount') {
                my $value       = $config->{$key};
                $invalid_amount = $value unless ($value =~ m/^\d+\.\d{2}$/);
            }
        } else {
            push(@missing, $key) 
        }
    }

    # Now generate the return string
    my $error = (
        (   @missing
            ? sprintf("is missing the following: '%s'", join("', '", @missing))
            : ""
        )
    );
    if ($invalid_amount) {
        $error .= " and " if ($error);
        $error .= sprintf(
            "the 'amount' '%s' is invalid, and should be in the form 'X.XX'",
            $invalid_amount,
        );
    }
    return $error;
}


=head1 CONFIG FILE FORMAT

This module supports reading a L<YAML|https://yaml.org/> based config file.

=head2 SAMPLE

Here is a sample config file:

    ---
    GnuCash:
      file:    /path/to/organization.gnucash
      format:  US
      memo:    Monthly membership dues
      account: Assets:Accounts Receivable

    MembershipTypes:
      default:
        name:    Standard Membership
        account: Income:Membership Dues
        amount:  30.00
      others:
        - name:    Special Membership
          match:   Special
          account: Income:Membership Dues
          amount:  50.00
        - name:    Company Membership
          match:   Company
          account: Income:Membership Dues
          amount:  80.00

=head2 CONFIG FILE SECTIONS

=over

=item GnuCash

This section contains parameters related to the GnuCash file.

Recognized keys are:

=over

=item file

The full path to the GnuCash file.

=item format

The date format to use when generating CSV files for import into GnuCash.

B<NOTE:> This must match the date format selcted in the GnuCash preferences.

Must be one of:

=over

=item US

MM/DD/YYYY

=item UK

DD/MM/YYYY

=item EUROPE

DD.MM.YYYY

=item ISO

YYYY-MM-DD

=back

DEFAULT: C<US>

=item memo

Optional description or memo used for the item on each invoice.

DEFAULT: C<Membership dues>

=item account

The GnuCash account used for posting the invoices, this is
typically C<Assets:Accounts Receivable>.

=back

=item MembershipTypes

This is a required section that configures how a membership type is determined, and
the details such as C<account> and C<amount> used for generating invoices.

This section recognizes the following sub sections:

=over

=item default

This required subsection provides details for the default membership type to apply
when no others match.

=item others

This optional subsection provides a list of sections that describe different types
of memberships.

=back

Each of these subsections supports the following keys:

=over

=item name

The name of the membership type.

=item account

The GnuCash account to use when generating invoices for this type of account.

=item amount

The amount to use when generating invoices for this type of account.

=item match

Used when examining the customer's C<notes> to determine what type of membership
for the customer.

B<NOTE:> The C<default> does not include a C<match> because it is used when none
of the C<others> match.

=back

=back 

=cut 

1;
