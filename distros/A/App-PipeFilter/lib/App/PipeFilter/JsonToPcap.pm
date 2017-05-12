package App::PipeFilter::JsonToPcap;
{
  $App::PipeFilter::JsonToPcap::VERSION = '0.005';
}

use Moose;
extends 'App::PipeFilter::Generic';

with (
  "App::PipeFilter::Role::Reader::Sysread",
  "App::PipeFilter::Role::Input::Json",
  "App::PipeFilter::Role::Transform::None",
	"App::PipeFilter::Role::Opener::PcapOutput",
  "App::PipeFilter::Role::Output::Pcap",
  "App::PipeFilter::Role::Writer::Pcap",
);

1;

__END__

# vim: ts=2 sw=2 expandtab
