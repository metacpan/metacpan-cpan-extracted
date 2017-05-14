#!perl
# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use v5.14;
use warnings;
use Attach::Stuff;

use constant WIDTH_MM       => 25;
use constant HEIGHT_MM      => 24;
use constant LENS_WIDTH_MM  => 8;
use constant LENS_HEIGHT_MM => 8;
use constant LENS_X_MM      => 8.5;
use constant LENS_Y_MM      => HEIGHT_MM - LENS_HEIGHT_MM - 5.5;


my $attach = Attach::Stuff->new({
    width                => WIDTH_MM,
    height               => HEIGHT_MM,
    screw_default_radius => 1.25,
    screw_holes          => [
        [ 2,      2        ],
        [ 2 + 21, 2        ],
        [ 2,      2 + 12.5 ],
        [ 2 + 21, 2 + 12.5 ],
    ],
});
my $svg = $attach->draw;
my ($draw) = $svg->getElements( 'g' );

# Draw lens
$draw->rectangle(
    x      => $attach->mm_to_px( LENS_X_MM ),
    y      => $attach->mm_to_px( LENS_Y_MM ),
    width  => $attach->mm_to_px( LENS_WIDTH_MM ),
    height => $attach->mm_to_px( LENS_HEIGHT_MM ),
);

print $svg->xmlify;
