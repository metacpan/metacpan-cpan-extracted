package Authen::NZRealMe::ServiceProvider::Builder;
$Authen::NZRealMe::ServiceProvider::Builder::VERSION = '1.19';
use warnings;
use strict;
use feature "switch";

use Term::ReadLine  qw();
use File::Path      qw(rmtree);
use File::Copy      qw(copy);
use Cwd             qw(getcwd);

my $prog_name = 'nzrealme';
my $term      = undef;

my @fields = (

    entity_id => <<EOF,
The 'Entity ID' is a URL that identifies the RealMe Login service privacy
domain that your service provider is a part of.  You must supply a value
here that has been registered with (or provided to you by) the RealMe Login
service. The format for this value is:

  https://<sp-domain>/<privacy-realm>/<application-name>
EOF

    url_assertion_consumer => <<EOF,
After a user has logged on, which URL on your site should the IdP redirect
the user back to?
EOF

    organization_name => <<EOF,
What is the name of the agency/company?
EOF

    organization_url => <<EOF,
What URL should be used to identify the agency/company?
EOF

    contact_company => <<EOF,
Which company name should be listed in the technical contact details?
EOF

);

my @field_names = map { $_ % 2 ? () : $fields[$_] } ( 0 .. $#fields );


sub build {
    my($class, $sp_class, %opt) = @_;

    _check_conf($opt{conf_dir});

    _init_term();
    my $scope = $class->_prompt_builder_scope() || return;

    if($scope =~ /login/) {
        $class->_build_meta($sp_class, 'login', %opt);
    }
    if($scope =~ /assertion/) {
        $class->_build_meta($sp_class, 'assertion', %opt);
    }
}


sub _init_term {
    $term = Term::ReadLine->new($prog_name);
    if($term->Attribs and $term->Attribs->can('ornaments')) {
        $term->Attribs->ornaments(0);
    }
    else {
        warn "Consider installing Term::ReadLine::Gnu for better terminal handling.\n\n";
    }
}


sub _prompt_builder_scope {
    my($class) = @_;

    print <<EOF;
This tool allows you to generate or edit the Service Provider metadata
required to integrate with the login service or the assertion service.

  1) Generate/edit SP metadata for only the login service
  2) Generate/edit SP metadata for only the assertion service
  3) Generate/edit SP metadata for both the login and assertion services
  4) Exit without making any changes

EOF

    my $resp = _menu_prompt("Select 1-4: ", qr{^[1234]$});
    return {
        1   => 'login',
        2   => 'assertion',
        3   => 'login,assertion',
    }->{$resp}
}


sub _build_meta {
    my($class, $sp_class, $type, %opt) = @_;

    my $conf_dir  = $opt{conf_dir};
    my $conf_path = $sp_class->_metadata_pathname($conf_dir, $type);
    _check_idp_metadata($conf_dir, $type);

    my $sp    = $class->_init_sp($sp_class, $conf_dir, $conf_path, $type);
    my $args  = $class->_prompt_field_values($sp);
    $sp->{$_} = $args->{$_} foreach @field_names;

    print "\nSaving metadata file: $conf_path\n\n";
    $sp->_write_file($conf_path, $sp->metadata_xml() . "\n");
}


sub _init_sp {
    my($class, $sp_class, $conf_dir, $conf_path, $type) = @_;

    if(-r $conf_path) {
        return $sp_class->new(conf_dir => $conf_dir, type => $type);
    }

    my $sp = $sp_class->new_defaults(conf_dir => $conf_dir, type => $type);

    my $other_type = $type eq 'login' ? 'assertion' : 'login';
    my $other_conf = $sp_class->_metadata_pathname($conf_dir, $other_type);
    if(-r $other_conf) {
        print "\nSetting initial defaults from $other_conf\n\n";
        my $other_sp = $sp_class->new(conf_dir => $conf_dir, type => $other_type);
        $sp->{$_} = $other_sp->{$_} foreach @field_names;
    }

    return $sp;
}


sub _prompt_field_values {
    my($class, $sp) = @_;

    my $args = { map { $_ => $sp->{$_} } @field_names };

    TRY: while(1) {
        for(my $i = 0; $i <= $#fields; $i += 2) {
            my $key    = $fields[$i];
            my $prompt = $fields[$i + 1];

            print "\n$prompt\n";
            my $field_ok = 0;
            my $value = $args->{$key};
            do {
                $value = $term->readline("$key> ", $value);
                my $method = "_validate_$key";
                $field_ok = $class->can($method) ? $class->$method($value) : 1;
            } until $field_ok;
            $args->{$key} = $value;
        }

        last TRY if _prompt_yes_no('Do you wish to save the results? (y/n) ', '');
        redo TRY if _prompt_yes_no('Do you wish to try again? (y/n) ', '');
        exit 1;
    }

    return $args;
}


sub _check_idp_metadata {
    my($conf_dir, $type) = @_;

    my $path = "$conf_dir/metadata-${type}-idp.xml";
    return if -e $path;

    warn "WARNING - File does not exist: $path\n"
       . "You should copy the IdP metadata file provided in the RealMe integration\n"
       . "bundle and save it using the filename shown above.\n\n";
}


sub _validate_id {
    my($class, $value) = @_;

    if($value =~ /\A[a-z_][\w-]*\z/i) {
        return 1;
    }
    elsif($value eq '') {
        print "ID must not be blank\n";
    }
    elsif($value =~ /\A[^a-z_]/i) {
        print "ID should start with a letter\n";
    }
    else {
        print "ID should contain only letters, numbers, _ and - characters\n";
    }
    return;
}


sub _validate_entity_id {
    my($class, $value) = @_;

    if($value =~ m{\Ahttps://[\w.-]+/[\w.-]+/[\w.-]+\z}i) {
        return 1;
    }
    elsif($value eq '') {
        print "Entity ID must not be blank\n";
    }
    else {
        print "Entity ID should match the URL pattern above\n";
    }
    return;
}


sub _check_conf {
    my $dir   = shift or die "conf_dir not defined\n";

    die "Config directory '$dir' does not exist\n" unless -d "$dir/.";

    my @missing = map {  -e "$dir/$_" ? () : "$dir/$_" } qw(
        sp-sign-crt.pem sp-sign-key.pem sp-ssl-crt.pem sp-ssl-key.pem
    );
    if(@missing) {
        my $hint = "Use 'nzrealme make-certs' to generate certificates";
        if(not grep /-key.pem/, @missing  and  -e "$dir/sp-sign.csr") {
            $hint = "You must save the signed certificate files you received "
                  . "from the CA\n(Certification Authority) using the "
                  . "filenames listed above.";
        }
        die join("\n",
            "The following key-pair files are missing:",
            map { " * $_" } @missing,
        ) . "\n\n$hint\n\n"
    }
}


sub _menu_prompt {
    my($prompt, $regex) = @_;

    while(1) {
        my $resp = $term->readline($prompt);
        return $resp if $resp =~ $regex;
    }
}


sub _prompt_yes_no {
    my($prompt, $default) = @_;

    while(1) {
        my $resp = $term->readline($prompt, $default);

        next unless defined $resp;
        return 1 if $resp =~ /^(y|yes)$/i;
        return 0 if $resp =~ /^(n|no)$/i;
    }
}


sub make_bundle {
    my($self, $sp) = @_;

    my $start_dir = getcwd();

    my($sp_name) = $sp->entity_id =~ m{//([^/]+)/};
    $sp_name =~ s{([.][^.]+){2}$}{};
    $sp_name =~ s{^(www|secure)[.]}{};
    die "Error determining entity name" unless $sp_name;

    my $idp_name = $sp->idp->entity_id;
    my($env) = $idp_name =~ m{www[.](mts|ite)};
    $env ||= 'prod';

    my $type     = $sp->type;
    my $conf_dir = $sp->conf_dir;
    my $work_dir = "$conf_dir/bundle";
    rmtree($work_dir) if -e $work_dir;

    mkdir($work_dir) or die "mkdir($work_dir)";
    chdir($work_dir) or die "chdir($work_dir)";

    my $zip_file      = $sp->conf_dir . "/${env}_${type}_sp_${sp_name}.zip";
    my $metadata_file = "${env}_sp_saml_metadata_${sp_name}.xml";
    my $signing_cert  = "${env}_sp_saml_sign_${sp_name}.cer";
    my $ssl_cert      = "${env}_sp_mutual_ssl_${sp_name}.cer";

    print "Assembling metadata and certificate files\n";

    copy("../metadata-$type-sp.xml" => $metadata_file)
        or die "error copying $conf_dir/metadata-sp.xml: $!\n";

    copy('../sp-sign-crt.pem' => $signing_cert)
        or die "error copying $conf_dir/sp-sign-crt.pem: $!\n";

    copy('../sp-ssl-crt.pem'  => $ssl_cert)
        or die "error copying $conf_dir/sp-ssl-crt.pem: $!\n";

    system('zip', $zip_file, $metadata_file, $signing_cert, $ssl_cert);


    chdir('..') or die "chdir('..'): $!";
    rmtree($work_dir);

    chdir($start_dir) or die "chdir($start_dir): $!";

    return $zip_file;
}


1;


__END__

=head1 NAME

Authen::NZRealMe::ServiceProvider::Builder - interactively create/edit Service Provider metadata

=head1 DESCRIPTION

This class is used for creating and editing the Service Provider metadata file
as well as generating a zip archive of the files (metadata and certificates)
needed by the IdP.


=head1 METHODS

=head2 build

Called by the C<< nzrealme make-meta >> command to create or edit the Service
Provider metadata file through a series of interactive questions and answers.

=head2 make_bundle

Called by the C<< nzrealme make-bundle >> command to create a zip archive of
the files needed by the IdP.  The archive will include the SP metadata and
certificate files.  Delegates to L<Authen::NZRealMe::ServiceProvider::Builder>


=head1 SEE ALSO

See L<Authen::NZRealMe> for documentation index.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2019 Enrolment Services, New Zealand Electoral Commission

Written by Grant McLean E<lt>grant@catalyst.net.nzE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


