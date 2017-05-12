package Baz;

use strict;
use warnings;

use Ambrosia::Meta;

class sealed
{
    public => [qw/pro_a pro_b pro_c pro_d pro_e pro_f pro_g pro_h pro_i pro_j pro_k pro_l pro_m pro_n pro_o pro_p pro_q pro_r pro_s pro_t pro_u pro_v pro_w pro_x pro_y pro_z/],
    private => [qw/pri_a pri_b pri_c pri_d pri_e pri_f pri_g pri_h pri_i pri_j pri_k pri_l pri_m pri_n pri_o pri_p pri_q pri_r pri_s pri_t pri_u pri_v pri_w pri_x pri_y pri_z/]
};

1;

