requires   "Data::Peek";
requires   "File::Copy";
requires   "File::Temp";  # ignore : CVE-2011-4116
requires   "Getopt::Long"             => "2.27";
requires   "Image::ExifTool";
requires   "Tk"                       => "804.027";
requires   "Tk::Animation";
requires   "Tk::Balloon";
requires   "Tk::Bitmap";
requires   "Tk::BrowseEntry";
requires   "Tk::Dialog";
requires   "Tk::DirTree";
requires   "Tk::JPEG";
requires   "Tk::PNG";
requires   "Tk::Pane";
requires   "Tk::Photo";
requires   "Tk::Pixmap";

recommends "Data::Peek"               => "0.53";
recommends "Getopt::Long"             => "2.58";
recommends "Image::ExifTool"          => "13.10";
recommends "Image::Info"              => "1.45";
recommends "Image::Size"              => "3.300";
recommends "Tk"                       => "804.036";
recommends "Tk::TIFF"                 => "0.11";
recommends "X11::Protocol"            => "0.56";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.22";

    suggests   "ExtUtils::MakeMaker"      => "7.70";
    };

on "test" => sub {
    requires   "Test::Harness";
    requires   "Test::More"               => "0.88";

    recommends "Test::More"               => "1.302207";
    };

feature "opt_format_tiff", "Support for TIFF" => sub {
    requires   "Tk::TIFF";
    };

feature "opt_xeleven_protocol", "Use X11::Protocol to get the screen size" => sub {
    requires   "X11::Protocol";
    };
