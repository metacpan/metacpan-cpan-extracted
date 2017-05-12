$c = {
       'source' => {
                     'regions' => {
                                    'regions' => [
                                                   'annulus(4164,4239,0,38.5198,n=2)'
                                                 ],
                                    'title' => 'source_region(s)'
                                  },
                     'table' => {
                                  'names' => [
                                               'reg',
                                               'counts',
                                               'pixels'
                                             ],
                                  'records' => [
                                                 {
                                                   'reg' => '1',
                                                   'pixels' => '1177',
                                                   'counts' => '5416.000'
                                                 },
                                                 {
                                                   'reg' => '2',
                                                   'pixels' => '3492',
                                                   'counts' => '33670.000'
                                                 }
                                               ],
                                  'widths' => [
                                                4,
                                                12,
                                                9
                                              ],
                                  'comments' => [
                                                  ' source_data'
                                                ]
                                }
                   },
       'hdr' => {
                  'source' => {
                                'data_file' => 'acisf05124N001_evt2_gsf_ds_lc_sorted.fits',
                                'arcsec/pixel' => '0.492'
                              },
                  'column units' => {
                                      'area' => 'arcsec**2',
                                      'surf_bri' => 'cnts/arcsec**2',
                                      'surf_err' => 'cnts/arcsec**2'
                                    },
                  'background' => {
                                    'data_file' => 'acisf05124N001_evt2_gsf_ds_lc_sorted.fits',
                                    'arcsec/pixel' => '0.492'
                                  }
                },
       'bkgd' => {
                   'regions' => {
                                  'regions' => [
                                                 'annulus(4264,4223,0,38.5198,n=2)'
                                               ],
                                  'title' => 'background_region(s)'
                                },
                   'table' => {
                                'names' => [
                                             'reg',
                                             'counts',
                                             'pixels'
                                           ],
                                'records' => [
                                               {
                                                 'reg' => '1',
                                                 'pixels' => '1177',
                                                 'counts' => '21.000'
                                               },
                                               {
                                                 'reg' => '2',
                                                 'pixels' => '3492',
                                                 'counts' => '88.000'
                                               }
                                             ],
                                'widths' => [
                                              4,
                                              12,
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
                                                     'net_counts' => '5395.000',
                                                     'reg' => '1',
                                                     'area' => '284.91',
                                                     'background' => '21.000',
                                                     'error' => '73.736',
                                                     'surf_bri' => '18.936',
                                                     'berror' => '4.583',
                                                     'surf_err' => '0.259'
                                                   },
                                                   {
                                                     'net_counts' => '33582.000',
                                                     'reg' => '2',
                                                     'area' => '845.29',
                                                     'background' => '88.000',
                                                     'error' => '183.734',
                                                     'surf_bri' => '39.728',
                                                     'berror' => '9.381',
                                                     'surf_err' => '0.217'
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
