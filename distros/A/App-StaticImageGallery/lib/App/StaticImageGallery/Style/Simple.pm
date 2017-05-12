package App::StaticImageGallery::Style::Simple;
BEGIN {
  $App::StaticImageGallery::Style::Simple::VERSION = '0.002';
}
use parent 'App::StaticImageGallery::Base::Style';

=head1 NAME

App::StaticImageGallery::Style::Simple - StaticImageGallery style Simple

=head1 VERSION

version 0.002

=cut

sub files {
    my $files = [
           {
             'base64' => 'aHRtbCwgYm9keSwgZGl2LCB1bCwgb2wsIGxpLCBkbCwgZHQsIGRkLCBmb3JtLCBmaWVsZHNldCwg
aW5wdXQsIHRleHRhcmVhLCBoMSwgaDIsIGgzLCBoNCwgaDUsIGg2LCBwcmUsIGNvZGUsIHAsIGJs
b2NrcXVvdGUsIGhyLCB0aCwgdGQgewogICAgbWFyZ2luOjA7CiAgICBwYWRkaW5nOjA7CiAgICBm
b250LWZhbWlseTp0cmVidWNoZXQgbXM7Cn0KCmltZyB7IGJvcmRlcjogMHB4OyB9CgphIHsKICAg
IGNvbG9yOiMwMDAwMDA7CiAgICB0ZXh0LWRlY29yYXRpb246bm9uZTsKfQoKI2NvbnRlbnQgewog
ICAgb3ZlcmZsb3c6aGlkZGVuOwp9CgoKI2hlYWRlciB7CiAgICBiYWNrZ3JvdW5kLWNvbG9yOiAj
NjYwMDAwOwogICAgYm9yZGVyLWNvbG9yOiM0NzAxMDE7CiAgICBwYWRkaW5nOjEwcHg7CiAgICBi
b3JkZXItYm90dG9tOjEwcHggc29saWQgYmxhY2s7CiAgICBib3JkZXItdG9wOjEwcHggc29saWQg
YmxhY2s7Cn0KI2hlYWRlciBoMSB7CiAgICBjb2xvcjojRkZGRkZGOwogICAgZm9udC1zaXplOjM0
cHg7CiAgICBmb250LXdlaWdodDpib2xkOwoKfQoKI2hlYWRlciBoMnsKICAgIGNvbG9yOiNGRkZG
RkY7CiAgICBmb250LXNpemU6MTRweDsKICAgIGxpbmUtaGVpZ2h0OjEuMTI1OwogICAgbWFyZ2lu
OjA7Cn0KCiNmb290ZXIgewogICAgYm9yZGVyLXRvcDoxcHggZG90dGVkICM2NjAwMDA7CiAgICBt
YXJnaW4tdG9wOiAxMHB4OwogICAgcGFkZGluZzogNXB4OwogICAgZm9udC1zaXplOjEycHg7Cn0K
Ci5jb250ZW50X3BhcnQgewogICAgY2xlYXI6IGJvdGg7Cn0KCi5jb250ZW50X3BhcnQgaDMgewog
ICAgYm9yZGVyLWJvdHRvbToxcHggZG90dGVkICM2NjAwMDA7CiAgICBjb2xvcjojNjYwMDAwOwog
ICAgZm9udC1mYW1pbHk6ImRyb2lkLXNhbnMtMSIsImRyb2lkLXNhbnMtMiIsIkx1Y2lkYSBHcmFu
ZGUiLCJMdWNpZGEgU2FucyBVbmljb2RlIix0YWhvbWEsdmVyZGFuYSxhcmlhbCxzYW5zLXNlcmlm
OwogICAgZm9udC1zaXplOjIwcHg7CiAgICBmb250LXdlaWdodDpub3JtYWw7CiAgICBsaW5lLWhl
aWdodDozMHB4OwogICAgcGFkZGluZy1sZWZ0OjVweDsKfQoKCi5pbWFnZV9ib3gsIC5pbWFnZV9p
bmRleCB7CiAgICBtYXJnaW4tbGVmdDogNXB4Owp9CgouaW1hZ2VfaW5kZXggLmltYWdlewogICAg
Zm9udC1mYW1pbHk6ImRyb2lkLXNhbnMtMSIsImRyb2lkLXNhbnMtMiIsIkx1Y2lkYSBHcmFuZGUi
LCJMdWNpZGEgU2FucyBVbmljb2RlIix0YWhvbWEsdmVyZGFuYSxhcmlhbCxzYW5zLXNlcmlmOwog
ICAgZm9udC1zaXplOjEwcHg7CiAgICBmb250LXdlaWdodDpub3JtYWw7Cn0KCi5pbWFnZV9pbmRl
eCAuaW1hZ2U6aG92ZXIgewogICAgYmFja2dyb3VuZC1jb2xvcjojQTlBOUE5Owp9CgouaW1hZ2Ug
ewogICAgZmxvYXQ6bGVmdDsKICAgIGJvcmRlcjoxcHggc29saWQgI0E5QTlBOTsKICAgIHBhZGRp
bmc6NXB4OwogICAgbWFyZ2luLXJpZ2h0OiA1cHg7CiAgICBtYXJnaW4tdG9wOiA1cHg7CiAgICB0
ZXh0LWFsaWduOiBjZW50ZXI7Cn0KCi5kaXJlY3RvcmllcyB7CiAgICAvKmZsb2F0OmxlZnQ7Ki8K
ICAgIGJvcmRlci1ib3R0b206MXB4IGRvdHRlZCAjNjYwMDAwOwogICAgY29sb3I6IzY2MDAwMDsK
ICAgIGZvbnQtc2l6ZToxNHB4OwogICAgcGFkZGluZy1ib3R0b206MXB4OwogICAgY2xlYXI6Ym90
aDsKfQoKI25hdmlnYXRpb24gewogICAgbWFyZ2luLWxlZnQ6NXB4OwovKiAgICBtYXJnaW4tdG9w
OjVweDsqLwp9CgouYnV0dG9ucyB1bCB7CiAgICBwYWRkaW5nLXRvcDogNXB4OwovKiAgICBwYWRk
aW5nLWJvdHRvbTogNXB4OyovCi8qICAgIG1hcmdpbjogNXB4OyovCn0KCi5idXR0b25zIGxpIHsK
ICAgIGRpc3BsYXk6IGlubGluZTsKICAgIGxpc3Qtc3R5bGU6bm9uZSBvdXRzaWRlIG5vbmU7CiAg
ICBtYXJnaW4tcmlnaHQ6IDVweDsKICAgIHBhZGRpbmctbGVmdDogNXB4OwogICAgcGFkZGluZy1y
aWdodDogNXB4OwogICAgYm9yZGVyOjFweCBzb2xpZCAjQTlBOUE5Owp9CgouYnV0dG9ucyBsaTpo
b3ZlciB7Ci8qICAgICAgICBib3JkZXI6IDFweCBzb2xpZCAjNjYwMDAwOyovCiAgICBiYWNrZ3Jv
dW5kLWNvbG9yOiNBOUE5QTk7Cn0KCgoubWV0YXRhYmxlIHsKICAgIGJvcmRlci1zcGFjaW5nOjNw
eDsKICAgIG1hcmdpbi1sZWZ0OiA1cHg7Cn0KCi5tZXRhdGFibGUgdGQgewogICAgYm9yZGVyLXRv
cDoxcHggZG90dGVkICM2NjAwMDA7Cn0KCi5tZXRhdGFibGUgdGggewogICAgY29sb3I6IzY2MDAw
MDsKICAgIGZvbnQtZmFtaWx5OiJkcm9pZC1zYW5zLTEiLCJkcm9pZC1zYW5zLTIiLCJMdWNpZGEg
R3JhbmRlIiwiTHVjaWRhIFNhbnMgVW5pY29kZSIsdGFob21hLHZlcmRhbmEsYXJpYWwsc2Fucy1z
ZXJpZjsKICAgIGZvbnQtc2l6ZToxNHB4OwogICAgZm9udC13ZWlnaHQ6bm9ybWFsOwogICAgdGV4
dC1hbGlnbjogbGVmdDsKfQ==
',
             'filename' => 'style.css'
           }
         ];

    return wantarray ? @$files : $files;
}
1;
__DATA__
__index__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
     "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <title>Static Image Gallery</title>
    <link rel="stylesheet" type="text/css" href="[% sig.config.data_dir_name %]/style.css">
</style>
</head>
<body>
    <div id='header'>
        <h1>Static Image Gallery</h1>
        <h2>[% work_dir %]</h2>
    </div>
    <div id='content'>
        [% IF link_to_parent_dir || ( dirs && dirs.size > 0 ) %]
        <div class='content_part'>
            <h3>Folders</h3>
            <div id='navigation' class='buttons'>
                <ul>
                    [% IF link_to_parent_dir %]
                        <li><a href='../index.html'>Parent</a></li>
                    [% END %]
                    [% FOREACH dir IN dirs %]
                        <li><a href='[% dir %]/index.html'>[% dir %]</a></li>
                    [% END %]
                </ul>
            </div>
        </div>
        [% END %]
        <div class='content_part'>
            <h3>Pictures</h3>
            <div class="image_index">
                [% FOREACH file IN images %]
                <div class="image" ><center>
                    <a href="[% sig.config.data_dir_name %]/[% file.original %].large.html">
                        <img title="[% file.title %]" alt="IMG_2342" src="[% sig.config.data_dir_name %]/[% file.thumbnail %]"/>
                    </a><br/>
                    <a href='[% sig.config.data_dir_name %]/[% file.original %].small.html'>Small</a>
                     | <a href='[% sig.config.data_dir_name %]/[% file.original %].medium.html'>Medium</a>
                     | <a href='[% sig.config.data_dir_name %]/[% file.original %].large.html'>Large</a>
                </center></div>
                [% END %]
            </div>
        </div>
    </div>
    <div id='footer'>
        <a href='http://search.cpan.org/dist/App-StaticImageGallery/'>App::StaticImageGallery</a>
         | Version: [% version %]
         | Created on [% now.strftime('%F') %] at [% now.strftime('%T' )%]
    </div>
</body>

__image__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
     "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <title>[% work_dir %] - [% current.original %] - [% size FILTER ucfirst %] - Static Image Gallery</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
    <div id='header'>
        <h1>Static Image Gallery</h1>
        <h2>[% work_dir %] - [% current.original %] - [% size FILTER ucfirst %]</h2>
    </div>
    <div id='content'>
        <div class='content_part'>
            <h3>Navigation</h3>
            <div id='navigation' class='buttons'>
            <ul>
                <li>
                    [% IF previous.original %]<a href='[% previous.original %].[% size %].html'>[% END %]
                        Previous
                    [% IF previous.original %]</a>[% END %]
                </li>
                <li><a href='../index.html'>Image list</a></li>
                <li>
                    [% IF next.original %]<a href='[% next.original %].[% size %].html'>[% END %]
                        Next
                    [% IF next.original %]</a>[% END %]
                </li>
            </ul>
            </div>
        </div>
        <div class='content_part'>
            <h3>Picture</h3>
            <div class="image_box">
                <div class="image" >
                    <img src='[% current.$size %]' />
                    <div class='buttons'>
                        <ul>
                            <li><a href='[% current.original %].small.html'>Small</a></li>
                            <li><a href='[% current.original %].medium.html'>Medium</a></li>
                            <li><a href='[% current.original %].large.html'>Large</a></li>
                            <li><a href='../[% current.original %]'>Original</a></li>
                        </ul>
                    </div>
                </div> 
            </div>
        </div>
        <div class='content_part'>
            <h3>Metadata</h3>
            <div class='content'>
                <table class='metatable'>
                    <tr><th>Key</th><th>Value</th></tr>
                    [% FOREACH meta IN current.metadata %]
                    <tr><td><b>[%meta.key%] :</b></td><td>[%meta.value%]</td></tr>
                    [% END %]
                </table>
            </div>
        </div>
    </div>
    <div id='footer'>
        <a href='http://search.cpan.org/dist/App-StaticImageGallery/'>App::StaticImageGallery</a>
         | Version: [% version %]
         | Created on [% now.strftime('%F') %] at [% now.strftime('%T' )%]
    </div>
</body>