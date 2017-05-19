package CCfnX::VagrantDeployer {
  use Moose::Role;
  use Paws;
  use Paws::Credential::ProviderChain;

  after deploy => sub {
    my $self = shift;

    my @lines = @{ $self->origin->Resource('Instance')->Properties->UserData->process_with_context($self->origin) };
    @lines = @{ $self->origin->Resource('Instance')->Properties->UserData->process_with_context($self->origin, \@lines) };

    my $content = join '', @lines;
    $content =~ s/\\/\\\\/;

    warn "I'm extending a 900 second (15 min) token with you're actual credentials to vagrant";

    my $creds = Paws::Credential::ProviderChain->new();

    my $aws_access_key = $creds->access_key;
    my $aws_secret_key = $creds->secret_key;
    my $aws_token      = $creds->session_token;

    my $vag_file = '
VAGRANTFILE_API_VERSION = "2"

$script = <<SCRIPT
#!/bin/bash
# Create temporary credentials
export AWS_ACCESS_KEY_ID=' . $aws_access_key . '
export AWS_SECRET_ACCESS_KEY=' . $aws_secret_key . '
export AWS_SESSION_TOKEN=' . $aws_token . '
cat > /etc/skel/.aws_creds <<ALIASES
export AWS_ACCESS_KEY_ID=' . $aws_access_key . '
export AWS_SECRET_ACCESS_KEY=' . $aws_secret_key . '
export AWS_SESSION_TOKEN=' . $aws_token . '
ALIASES
' . $content . '
# Clean temporary credentials
rm -f /etc/skel/.aws_creds
find /home -type f -name ".aws_creds" -delete
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "' . $self->params->{ami} . '"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.network "private_network", type: "dhcp"
  config.vm.provider :virtualbox do |vb|
    vb.gui = true
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end
  config.vm.provision "shell", inline: $script
end
';

    open (my $file, '>', 'Vagrantfile');
    print $file $vag_file;
    close $file;

    #print $vag_file;
    #system 'vagrant','up';
  };

  before redeploy => sub {
    die "VagrantDeployer cannot redeploy yet. Please deploy again";
  };

  before undeploy => sub {
    system 'vagrant','destroy','-f';
    #die "VagrantDeployer cannot undeploy yet. Please manually delete resources";
  };

}

1;
