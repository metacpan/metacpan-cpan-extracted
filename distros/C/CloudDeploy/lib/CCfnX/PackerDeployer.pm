package CCfnX::PackerDeployer {
  use Moose::Role;
  use JSON;

  after deploy => sub {
    my $self = shift;

    my @lines = @{ $self->origin->Resource('Instance')->Properties->UserData->process_with_context($self->origin) };
    @lines = @{ $self->origin->Resource('Instance')->Properties->UserData->process_with_context($self->origin, \@lines) };
    chomp @lines;

    my $att_name = 'Bucket';
    my $att = $self->origin->params->meta->find_attribute_by_name($att_name);
    my $aws_access_key = $att->get_info($self->origin->params->$att_name, 'appbucket/codeuser/accesskey');
    my $aws_secret_key = $att->get_info($self->origin->params->$att_name, 'appbucket/codeuser/secretkey');

    my $packer_def = {
      builders =>     [ { type => "docker", image => "ubuntu", export_path => "image.tar" } ],
      provisioners => [ { type => "shell", inline => [
'#!/bin/bash',
"export AWS_ACCESS_KEY_ID=$aws_access_key",
"export AWS_SECRET_ACCESS_KEY=$aws_secret_key",
"cat > /etc/skel/.aws_creds <<ALIASES",
"export AWS_ACCESS_KEY_ID=$aws_access_key",
"export AWS_SECRET_ACCESS_KEY=$aws_secret_key",
"ALIASES",
@lines,

                                           ]
                        }
      ]
    };

    open (my $file, '>', 'packer.config');
    print $file encode_json($packer_def);
    close $file;

    #system 'packer','build';
  };

  before redeploy => sub {
    die "PackerDeployer cannot redeploy yet. Please deploy again";
  };

  before undeploy => sub {
    die "PackerDeployer cannot undeploy yet. Please manually delete resources";
  };
}

1;
