#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use lib '../blib';
use Concierge::Users;
use File::Spec;
use Cwd 'abs_path';

my $base_dir = abs_path('./');
my $data_dir = File::Spec->catdir($base_dir, 'data');
my $config_file = File::Spec->catfile($data_dir, 'users-config.json');

my $command = shift @ARGV;

# No command - show help
unless ($command) {
    say "Usage: $0 <command> [args]";
    say "Commands:";
    say "  setup                      - Initialize file backend (CSV)";
    say "  add user_id=X email=Y ...  - Register new user";
    say "  get <user_id>              - Retrieve user";
    say "  list                       - List all users";
    say "  update <user_id> k=v ...   - Update user";
    say "  delete <user_id>           - Delete user";
    exit;
}

# SETUP command
if ($command eq 'setup') {
    say "Setting up File backend (CSV)...";
    my $config = {
        storage_dir => $data_dir,
        backend => 'file',
        file_format => 'csv',
        config_file => $config_file,
    };
    my $result = Concierge::Users->setup($config);
    say $result->{success} ? "✅ Setup successful: $result->{message}" : "❌ Setup failed: $result->{message}";
    if ($result->{success}) {
        say "Config file: $result->{config_file}";
    }
    exit;
}

# Load existing config
unless (-e $config_file) {
    die "❌ Config not found. Run '$0 setup' first.\n";
}

my $users = Concierge::Users->new($config_file);

# ADD command
if ($command eq 'add') {
    # Show field help if no arguments
    unless (@ARGV) {
        say "Available fields for 'add':\n";
        my $fields = $users->get_user_fields();
        my (@required, @optional);

        foreach my $field (@$fields) {
            my $def = $users->get_field_definition($field);
            next unless $def;
            # Skip system fields (auto-generated) except user_id
            next if $def->{type} eq 'system' && $field ne 'user_id';
            if ($def->{required}) {
                push @required, $field;
            } else {
                push @optional, $field;
            }
        }

        say "Required fields:";
        foreach my $field (@required) {
            my $def = $users->get_field_definition($field);
            my $label = $def->{label} || $field;
            my $type = $def->{type} || '';
            my $line = "  $field ($type) - $label";
            if ($type eq 'enum' && $def->{options} && @{$def->{options}}) {
                my $opts = join(', ', @{$def->{options}});
                $line .= " [$opts]";
            }
            say $line;
        }

        say "\nOptional fields:";
        foreach my $field (@optional) {
            my $def = $users->get_field_definition($field);
            my $label = $def->{label} || $field;
            my $type = $def->{type} || '';
            my $line = "  $field ($type) - $label";
            if ($type eq 'enum' && $def->{options} && @{$def->{options}}) {
                my $opts = join(', ', @{$def->{options}});
                $line .= " [$opts]";
            }
            say $line;
        }

        say "\nUsage: $0 add user_id=YOUR_ID moniker=YOUR_MONIKER email=your\@example.com ...";
        exit;
    }

    my %params = map { split(/=/, $_, 2) } @ARGV;
    say "Adding user: $params{user_id}";
    my $result = $users->register_user(\%params);
    say $result->{success} ? "✅ $result->{message}" : "❌ $result->{message}";
    if ($result->{warnings}) {
        say "Warnings: " . join(', ', @{$result->{warnings}});
    }
    exit;
}

# GET command
if ($command eq 'get') {
    my $user_id = shift @ARGV or die "Usage: $0 get <user_id>\n";
    my $result = $users->get_user($user_id);
    if ($result->{success}) {
        say "✅ User found:";
#        foreach my $field (keys %{$result->{user}}) {
        foreach my $field ( $users->get_user_fields->@* ) {
            my $value = $result->{user}{$field} // '<undef>';
            say "  $field: $value";
        }
    } else {
        say "❌ $result->{message}";
    }
    exit;
}

# LIST command
if ($command eq 'list') {
    my $result = $users->list_users();
    if ($result->{success} && $result->{user_ids}) {
        my $count = $result->{total_count};
        say "✅ Found $count user(s):\n";

        # Define fields to show in table
        my @fields = qw(user_id moniker email phone first_name last_name);

        # Fetch full data for each user
        my @users_data;
        foreach my $user_id (@{$result->{user_ids}}) {
            my $user_result = $users->get_user($user_id);
            if ($user_result->{success}) {
                push @users_data, $user_result->{user};
            }
        }

        # Calculate column widths
        my %widths;
        foreach my $field (@fields) {
            $widths{$field} = length($field);
        }
        foreach my $user (@users_data) {
            foreach my $field (@fields) {
                my $val = $user->{$field} // '';
                my $len = length($val);
                $widths{$field} = $len if $len > $widths{$field};
            }
        }

        # Add padding
        foreach my $field (@fields) {
            $widths{$field} += 2;
        }

        # Print header
        my $header_line = '';
        foreach my $field (@fields) {
            $header_line .= sprintf("%-${widths{$field}}s", $field);
        }
        say $header_line;

        # Print separator
        my $sep_line = '';
        foreach my $field (@fields) {
            $sep_line .= '-' x ($widths{$field} - 1) . ' ';
        }
        say $sep_line;

        # Print user rows
        foreach my $user (@users_data) {
            my $line = '';
            foreach my $field (@fields) {
                my $val = $user->{$field} // '';
                $line .= sprintf("%-${widths{$field}}s", $val);
            }
            say $line;
        }
    } elsif ($result->{success}) {
        say "✅ No users found";
    } else {
        say "❌ $result->{message}";
    }
    exit;
}

# UPDATE command
if ($command eq 'update') {
    my $user_id = shift @ARGV or die "Usage: $0 update <user_id> field=value ...\n";

    # Show field help if no field=value arguments
    unless (@ARGV) {
        say "Current data for '$user_id':\n";

        # Get current user data
        my $user_result = $users->get_user($user_id);
        if ($user_result->{success}) {
            my $current_data = $user_result->{user};

            # Get updatable fields
            my $fields = $users->get_user_fields();

            foreach my $field (@$fields) {
                my $def = $users->get_field_definition($field);
                next unless $def;

                # Skip system fields and user_id
                next if $def->{type} eq 'system';
                next if $field eq 'user_id';

                my $label = $def->{label} || $field;
                my $type = $def->{type} || '';
                my $current_val = $current_data->{$field} // '';

                # Format the value
                if ($current_val eq '' || $current_val eq '0000-00-00 00:00:00') {
                    $current_val = '<empty>';
                }

                my $line = "  $field ($type): $current_val";
                if ($type eq 'enum' && $def->{options} && @{$def->{options}}) {
                    my $opts = join(', ', @{$def->{options}});
                    $line .= "\n    Options: [$opts]";
                }
                say $line;
            }
        } else {
            say "❌ User '$user_id' not found";
        }

        say "\nUsage: $0 update $user_id email=new\@example.com phone=555-9999 ...";
        exit;
    }

    my %params = map { split(/=/, $_, 2) } @ARGV;
    say "Updating user: $user_id";
    my $result = $users->update_user($user_id, \%params);
    say $result->{success} ? "✅ $result->{message}" : "❌ $result->{message}";
    if ($result->{warnings}) {
        say "Warnings: " . join(', ', @{$result->{warnings}});
    }
    exit;
}

# DELETE command
if ($command eq 'delete') {
    my $user_id = shift @ARGV or die "Usage: $0 delete <user_id>\n";
    say "Deleting user: $user_id";
    my $result = $users->delete_user($user_id);
    say $result->{success} ? "✅ $result->{message}" : "❌ $result->{message}";
    exit;
}

if ($command eq 'load_test_data') {
    say "Loading test data ...";
    my @db_fields	= $users->get_user_fields->@*;
    say join ' ' => @db_fields;
    my %OKfields	= map { $_ => 1 } @db_fields;
    my $hdr_line	= <DATA>;
    chomp $hdr_line;
    my @header		= split "\t" => $hdr_line;
    say join ' ' => @header;
    my $cntr	= 0;
    while (my $u = <DATA>) {
    	chomp $u;
    	my @record	= map { $_ || '' } split "\t" => $u;
    	say join ' ' => @record;
    	my %data; @data{@header} = @record;
    	%data	= map {  $OKfields{ $_ } ? ($_ => $data{$_} || '' ) : () } (@header);
    	my $result = $users->register_user(\%data);
    	say $result->{success} ? "✅ $result->{message}" : "❌ $result->{message}";
    	$cntr++ if $result->{success};
    	if ($result->{warnings}) {
    		say "Warnings: " . join(', ', @{$result->{warnings}});
    	}
    }
    say "OK, $cntr test records added to the Users data store.";
	exit;
}

die "Unknown command: $command\n";


__DATA__
user_id	last_login_date	last_mod_date	organization	first_name	last_name	moniker	phone	text_ok	email	user_status	access_level	term_ends	first_act
alice	2025-09-09T19:44:59	2025-07-25 12:15:54		Alice	Archer	AA	555-100-0001		alice@example.com	OK	admin	2027-01-01
bob	2025-10-20T10:35:30			Bob	Baker	BB	555-100-0002		bob@example.com	OK	staff	2027-01-01
carol	2025-09-09T20:54:49			Carol	Chen	CC	555-100-0003		carol@example.com	OK	staff	2027-01-03
dave	2025-07-15T18:10:02			Dave	Davis	DD	555-100-0004		dave@example.com	OK	staff	2026-12-31
eve	2025-08-28T16:21:03			Eve	Evans	EE	555-100-0005		eve@example.com	OK	staff	2026-12-31
frank	2025-08-21T17:06:26			Frank	Foster	FF	555-100-0006		frank@example.com	OK	staff	2026-12-31
grace	2025-07-29T16:16:47			Grace	Green	GG	555-100-0007		grace@example.com	OK	staff	2026-12-31
henry	2025-09-15T16:15:11			Henry	Hall	HH	555-100-0008		henry@example.com	OK	staff	2026-12-31
iris	2025-07-03T11:52:13			Iris	Ingram	II	555-100-0009		iris@example.com	OK	staff	2026-12-31
jack	2025-10-19T07:02:35			Jack	Jones	JJ	555-100-0010		jack@example.com	OK	admin	2027-01-04
kate	2025-06-28T16:37:17			Kate	Kim	KK	555-100-0011		kate@example.com	OK	staff	2027-01-06
liam	2025-07-28T13:22:40			Liam	Lee	LL	555-100-0012		liam@example.com	OK	staff	2027-01-04
maya	2025-08-12T10:04:21			Maya	Moore	MM	555-100-0013		maya@example.com	OK	staff	2027-01-04
nina	2025-08-13T11:53:57			Nina	Nash	NN	555-100-0014		nina@example.com	OK	staff	2027-01-04
