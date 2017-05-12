$c = {
       'source' => {
                     'regions' => {
                                    'regions' => [
                                                   '# Region file format: DS9 version 4.0',
                                                   '# Filename: /data/mimir3/gaetz/reproj.cxo.e0102/imgcorr/bin1/0.481-0.614/5124/obs5124_O7Hea_bin1_img_S3.fits',
                                                   'global color=green font="helvetica 10 normal" select=1 highlite=1 edit=1 move=1 delete=1 include=1 fixed=0 source',
                                                   'physical',
                                                   'ellipse(4093.5,4095.5,0,0,8.2,9,16.4,18,24.6,27,32.8,36,41,45,20)'
                                                 ],
                                    'title' => 'source_region(s)'
                                  },
                     'table' => {
                                  'names' => [
                                               'reg',
                                               'counts',
                                               'pixels',
                                               'avg_exp'
                                             ],
                                  'records' => [
                                                 {
                                                   'avg_exp' => '1279842.077',
                                                   'reg' => '1',
                                                   'pixels' => '231',
                                                   'counts' => '180.000'
                                                 },
                                                 {
                                                   'avg_exp' => '1279745.292',
                                                   'reg' => '2',
                                                   'pixels' => '696',
                                                   'counts' => '467.000'
                                                 },
                                                 {
                                                   'avg_exp' => '1279787.328',
                                                   'reg' => '3',
                                                   'pixels' => '1156',
                                                   'counts' => '2276.000'
                                                 },
                                                 {
                                                   'avg_exp' => '1279767.291',
                                                   'reg' => '4',
                                                   'pixels' => '1634',
                                                   'counts' => '2443.000'
                                                 },
                                                 {
                                                   'avg_exp' => '1279632.319',
                                                   'reg' => '5',
                                                   'pixels' => '2086',
                                                   'counts' => '724.000'
                                                 }
                                               ],
                                  'widths' => [
                                                4,
                                                12,
                                                9,
                                                9
                                              ],
                                  'comments' => [
                                                  ' source_data'
                                                ]
                                }
                   },
       'hdr' => {
                  'source' => {
                                'data_file' => 'cts.fits',
                                'interval' => 'energy=350:500',
                                'exp_correction' => 'expmap.fits',
                                'arcsec/pixel' => '0.492'
                              },
                  'column units' => {
                                      'area' => 'arcsec**2',
                                      'surf_bri' => 'cnts/arcsec**2/expval',
                                      'surf_err' => 'cnts/arcsec**2/expval'
                                    },
                  'background' => {
                                    'data_file' => 'cts.fits',
                                    'interval' => 'energy=350:500',
                                    'exp_correction' => 'expmap.fits',
                                    'arcsec/pixel' => '0.492'
                                  }
                },
       'bkgd' => {
                   'regions' => {
                                  'regions' => [
                                                 '# Region file format: DS9 version 4.0',
                                                 '# Filename: /data/mimir3/gaetz/reproj.cxo.e0102/imgcorr/bin1/0.481-0.614/5124/obs5124_O7Hea_bin1_img_S3.fits',
                                                 'global color=green font="helvetica 10 normal" select=1 highlite=1 edit=1 move=1 delete=1 include=1 fixed=0 source',
                                                 'physical',
                                                 'box(4095,4095.5,125,124,0)',
                                                 '-circle(4093.5,4095.5,45.233081)'
                                               ],
                                  'title' => 'background_region(s)'
                                },
                   'table' => {
                                'names' => [
                                             'reg',
                                             'counts',
                                             'pixels',
                                             'avg_exp'
                                           ],
                                'records' => [
                                               {
                                                 'avg_exp' => '1279378.579',
                                                 'reg' => 'all',
                                                 'pixels' => '9067',
                                                 'counts' => '70.000'
                                               }
                                             ],
                                'widths' => [
                                              4,
                                              12,
                                              9,
                                              9
                                            ],
                                'comments' => [
                                                ' background_data'
                                              ]
                              }
                 },
       'bkgd_sub' => {
                       'table' => {
                                    'names' => [
                                                 'reg',
                                                 'net_counts',
                                                 'error',
                                                 'background',
                                                 'berror',
                                                 'area',
                                                 'surf_bri',
                                                 'surf_err'
                                               ],
                                    'records' => [
                                                   {
                                                     'net_counts' => '178.216',
                                                     'reg' => '1',
                                                     'area' => '55.92',
                                                     'background' => '1.784',
                                                     'error' => '13.418',
                                                     'surf_bri' => '0.000',
                                                     'berror' => '0.213',
                                                     'surf_err' => '0.000'
                                                   },
                                                   {
                                                     'net_counts' => '461.625',
                                                     'reg' => '2',
                                                     'area' => '168.48',
                                                     'background' => '5.375',
                                                     'error' => '21.620',
                                                     'surf_bri' => '0.000',
                                                     'berror' => '0.642',
                                                     'surf_err' => '0.000'
                                                   },
                                                   {
                                                     'net_counts' => '2267.072',
                                                     'reg' => '3',
                                                     'area' => '279.83',
                                                     'background' => '8.928',
                                                     'error' => '47.719',
                                                     'surf_bri' => '0.000',
                                                     'berror' => '1.067',
                                                     'surf_err' => '0.000'
                                                   },
                                                   {
                                                     'net_counts' => '2430.381',
                                                     'reg' => '4',
                                                     'area' => '395.53',
                                                     'background' => '12.619',
                                                     'error' => '49.450',
                                                     'surf_bri' => '0.000',
                                                     'berror' => '1.508',
                                                     'surf_err' => '0.000'
                                                   },
                                                   {
                                                     'net_counts' => '707.892',
                                                     'reg' => '5',
                                                     'area' => '504.95',
                                                     'background' => '16.108',
                                                     'error' => '26.976',
                                                     'surf_bri' => '0.000',
                                                     'berror' => '1.925',
                                                     'surf_err' => '0.000'
                                                   }
                                                 ],
                                    'widths' => [
                                                  4,
                                                  12,
                                                  9,
                                                  12,
                                                  9,
                                                  9,
                                                  9,
                                                  9
                                                ],
                                    'comments' => [
                                                    ' background-subtracted results'
                                                  ]
                                  }
                     }
     };
