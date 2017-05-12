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
                                               'pixels',
                                               'sumcnts',
                                               'sumpix'
                                             ],
                                  'records' => [
                                                 {
                                                   'reg' => '1',
                                                   'sumcnts' => '5416.000',
                                                   'sumpix' => '1177',
                                                   'pixels' => '1177',
                                                   'counts' => '5416.000'
                                                 },
                                                 {
                                                   'reg' => '2',
                                                   'sumcnts' => '39086.000',
                                                   'sumpix' => '4669',
                                                   'pixels' => '3492',
                                                   'counts' => '33670.000'
                                                 }
                                               ],
                                  'widths' => [
                                                4,
                                                12,
                                                9,
                                                12,
                                                9
                                              ],
                                  'comments' => [
                                                  ' summed_source_data'
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
                                    'constant_value' => '0.000000'
                                  }
                },
       'sum_bkgd_sub' => {
                           'table' => {
                                        'names' => [
                                                     'upto',
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
                                                         'area' => '284.91',
                                                         'background' => '0.000',
                                                         'berror' => '0.000',
                                                         'upto' => '1',
                                                         'net_counts' => '5416.000',
                                                         'error' => '73.593',
                                                         'surf_bri' => '19.010',
                                                         'surf_err' => '0.258'
                                                       },
                                                       {
                                                         'area' => '1130.20',
                                                         'background' => '0.000',
                                                         'berror' => '0.000',
                                                         'upto' => '2',
                                                         'net_counts' => '39086.000',
                                                         'error' => '197.702',
                                                         'surf_bri' => '34.583',
                                                         'surf_err' => '0.175'
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
                                                        ' summed background-subtracted results'
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
                                                     'net_counts' => '5416.000',
                                                     'reg' => '1',
                                                     'area' => '284.91',
                                                     'background' => '0.000',
                                                     'error' => '73.593',
                                                     'surf_bri' => '19.010',
                                                     'berror' => '0.000',
                                                     'surf_err' => '0.258'
                                                   },
                                                   {
                                                     'net_counts' => '33670.000',
                                                     'reg' => '2',
                                                     'area' => '845.29',
                                                     'background' => '0.000',
                                                     'error' => '183.494',
                                                     'surf_bri' => '39.833',
                                                     'berror' => '0.000',
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
