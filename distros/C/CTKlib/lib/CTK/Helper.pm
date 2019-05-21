package CTK::Helper; # $Id: Helper.pm 264 2019-05-17 21:17:51Z minus $
use strict;
use utf8;

=encoding utf8

=head1 NAME

CTK::Helper - Helper for building CTK scripts. CLI user interface

=head1 VIRSION

Version 2.70

=head1 SYNOPSIS

none

=head1 DESCRIPTION

Helper for building CTK scripts

No public subroutines

=head2 nope, skip, yep

Internal use only!

See C<README>

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

Coming soon

=head1 SEE ALSO

L<CTK>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '2.70';

use feature qw/say/;
#use autouse 'Data::Dumper' => qw(Dumper); #$Data::Dumper::Deparse = 1;

use base qw/ CTK::App /;

use CTK;
use CTK::Util;
use CTK::Skel;
use Term::ANSIColor qw/colored/;
use File::Spec;
use Cwd qw/getcwd/;
use Text::SimpleTable;
use File::Copy::Recursive qw(dircopy dirmove);

use constant {
    PROJECT_NAME            => "Foo",
    PROJECT_TYPE_DEFAULT    => "regular",
    PROJECT_TYPES   => {
        regular => [qw/common extra regular/],
        module  => [qw/common module/],
        tiny    => [qw/tiny/],
        daemon  => [qw/common extra daemon/],
    },
    PROJECT_SKELS   => {
        common  => "CTK::Skel::Common",
        regular => "CTK::Skel::Regular",
        module  => "CTK::Skel::Module",
        tiny    => "CTK::Skel::Tiny",
        daemon  => "CTK::Skel::Daemon",
        extra   => "CTK::Skel::Extra",
    },
    PROJECT_VARS => [qw/
            CTK_VERSION
            PROJECT_NAME
            PROJECT_NAMEL
            PROJECT_TYPE
            GMT
        /],
};

__PACKAGE__->register_handler(
    handler     => "usage",
    description => "Usage",
    code => sub {
### CODE:
    my ($self, $meta, @params) = @_;
    say(<<USAGE);
Usage:
    ctklib [-dv] [-t regular|tiny|module|daemon] [-D /project/dir] create [PROJECTNAME]
    ctklib create <PROJECTNAME>
    ctklib create
    ctklib test
    ctklib -H
    ctklib -V
USAGE
    return 0;
});

__PACKAGE__->register_handler(
    handler     => "version",
    description => "CTK Version",
    code => sub {
### CODE:
    my ($self, $meta, @params) = @_;
    say sprintf("CTK Version: %s.%s", CTK->VERSION, $self->revision);
    return 1;
});

__PACKAGE__->register_handler(
    handler     => "test",
    description => "CTK Testing",
    code => sub {
### CODE:
    my ($self, $meta, @params) = @_;
    say("Testing CTK environment...");
    my $summary = 1; # OK

    # CTK version
    my $ver = CTK->VERSION;
    if ($ver) {
        yep("CTK version: %s", $ver);
    } else {
        $summary = nope("Can't get CTK version");
    }

    # CTK version
    my $rev = $self->revision;
    if ($rev) {
        yep("CTK revision: %s", $rev);
    } else {
        $summary = nope("Can't get CTK revision");
    }

    # Handlers list
    my @handlers = $self->list_handlers;
    if (@handlers) {
        yep("Handlers: %s", join(", ", @handlers));
    } else {
        $summary = nope("Can't get list of handlers");
    }

    # Allowed skels
    my $skel = new CTK::Skel ( -skels => PROJECT_SKELS );
    if (my @skels = $skel->skels) {
        yep("Allowed skeletons: %s", join(", ", @skels));
    } else {
        $summary = nope("Can't get list of skeletons");
    }

    # Summary
    if ($summary) {
        yep("All tests was passed");
    } else {
        nope("Testing failed");
    }
    print "\n";

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "create",
    description => "Project making",
    code => sub {
### CODE:
    my ($self, $meta, @params) = @_;
    my $projectname = @params ? shift @params : '';
    my $tty = $self->option("tty");
    my $yes = $self->option("yes") ? 1 : 0;
    my $type = $self->option("type");
    my $dir = $self->option("dir");
    my %vars = (
        CTK_VERSION => CTK->VERSION,
        GMT => CTK::Util::dtf("%w %MON %_D %hh:%mm:%ss %YYYY %Z", time(), 'GMT'), # scalar(gmtime)." GMT"
    );

    # Project name
    {
        unless ($projectname) {
            $projectname = ($tty && !$yes)
                ? $self->cli_prompt('Project Name:', PROJECT_NAME)
                : PROJECT_NAME;
        }
        $projectname =~ s/[^a-z0-9_]/X/ig;
        if ($tty && $projectname !~ /^[A-Z]/) {
            printf "The selected name begins with a small letter: %s\n", $projectname;
            if (!$yes) {
                return skip('Operation aborted')
                    if $self->cli_prompt('Are you sure you want to continue?:','no') !~ /^\s*y/i;
            }
        }
        $vars{PROJECT_NAME} = $projectname;
        $vars{PROJECT_NAMEL} = lc($projectname);
    }

    # Project type
    {
        my $atypes = PROJECT_TYPES;
        unless ($type) {
            $type = ($tty && !$yes)
                ? lc($self->cli_prompt(
                        sprintf('Project type (%s):', join(", ", keys(%$atypes))),
                        PROJECT_TYPE_DEFAULT
                    ))
                : PROJECT_TYPE_DEFAULT;
        }
        return nope('Incorrect type') unless $atypes->{$type};
        $vars{PROJECT_TYPE} = $type;
    }

    # Directory
    $dir ||= ($tty && !$yes)
        ? $self->cli_prompt('Please provide destination directory:', File::Spec->catdir(getcwd(), $projectname))
        : File::Spec->catdir(getcwd(), $projectname);
    if (-e $dir) {
        if ($tty) {
            if (!$yes) {
                return skip('Operation aborted')
                    if $self->cli_prompt(sprintf('Directory "%s" already exists! Are you sure you want to continue?:', $dir),'no') !~ /^\s*y/i;
            }
        } else {
            return skip('Directory "%s" already exists! Operation forced aborted because pipe mode is enabled', $dir);
        }
    }

    # Summary
    if ($tty) {
        my $tbl = Text::SimpleTable->new(
                [ 25, 'PARAM' ],
                [ 57, 'VALUE / MESSAGE' ],
            );
        $tbl->row( $_, $vars{$_} ) for @{(PROJECT_VARS)};
        $tbl->hr;
        $tbl->row( "DIRECTORY", $dir );
        print("\n",colored(['cyan on_black'], "SUMMARY TABLE:"),"\n", colored(['cyan on_black'], $tbl->draw), "\n");
        return skip('Operation aborted') if !$yes
            && $self->cli_prompt('All right?:','yes') !~ /^\s*y/i;
    }

    # Start building!
    {
        my $tmpdirobj = File::Temp->newdir(TEMPLATE => lc($projectname).'XXXXX', TMPDIR => 1);
        my $tmpdir = $tmpdirobj->dirname;
        my $skel = new CTK::Skel (
                -name   => $projectname,
                -root   => $tmpdir,
                -skels  => PROJECT_SKELS,
                -debug  => $tty,
                -vars   => {
                        CTKVERSION      => CTK->VERSION,
                        PROJECT_VERSION => "1.00",
                        AUTHOR          => "Mr. Anonymous",
                        ADMIN           => "root\@example.com",
                        HOMEPAGE        => "https://www.example.com",
                    },
            );

        #$tmpdir = File::Spec->catdir($self->tempdir, lc($projectname));
        printf("Creating %s project %s to %s...\n\n", $type, $projectname, $tmpdir);

        my $skels = PROJECT_TYPES()->{$type} || [];
        foreach my $s (@$skels) {
            if ($skel->build($s, $tmpdir, {%vars})) {
                yep("The %s files have been successfully processed", $s);
            } else {
                return nope("Can't build the project to \"%s\" directory", $tmpdir);
            }
        }

        # Move to destination directory
        if (dirmove($tmpdir, $dir)) {
            yep("Project was successfully created!");
            printf("\nAll the project files was located in %s directory\n", $dir);
        } else {
            return nope("Can't move directory from \"%s\" to \"%s\": %s", $tmpdir, $dir, $!);
        }
    }

    return 0;
});

# Colored print
sub yep {
    print(colored(['green on_black'], '[  OK  ]'), ' ', sprintf(shift, @_), "\n");
    return 1;
}
sub nope {
    print(colored(['red on_black'], '[ FAIL ]'), ' ', sprintf(shift, @_), "\n");
    return 0;
}
sub skip {
    print(colored(['yellow on_black'], '[ SKIP ]'), ' ', sprintf(shift, @_), "\n");
    return 1;
}

1;

__END__
