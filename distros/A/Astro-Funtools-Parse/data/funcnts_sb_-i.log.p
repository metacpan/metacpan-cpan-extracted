$c = {
       'source' => {
                     'regions' => {
                                    'regions' => [
                                                   '# Region file format: DS9 version 4.0',
                                                   '# Filename: /data/mimir3/gaetz/reproc.cxo.e0102/5124/acisf05124N001_evt2_gsf_ds_lc_sorted.fits[EVENTS]',
                                                   'global color=green font="helvetica 10 normal" select=1 highlite=1 edit=1 move=1 delete=1 include=1 fixed=0 source',
                                                   'physical',
                                                   'circle(4163,4240,49.456451)'
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
                                                   'pixels' => '7685',
                                                   'counts' => '1085.000'
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
                                'interval' => 'energy=350:500',
                                'arcsec/pixel' => '0.492'
                              },
                  'column units' => {
                                      'area' => 'arcsec**2',
                                      'surf_bri' => 'cnts/arcsec**2',
                                      'surf_err' => 'cnts/arcsec**2'
                                    },
                  'background' => {
                                    'data_file' => 'acisf05124N001_evt2_gsf_ds_lc_sorted.fits'
                                  }
                },
       'bkgd' => {
                   'regions' => {
                                  'regions' => [
                                                 '# Region file format: DS9 version 4.0',
                                                 '# Filename: /data/mimir3/gaetz/reproc.cxo.e0102/5124/acisf05124N001_evt2_gsf_ds_lc_sorted.fits[EVENTS]',
                                                 'global color=green font="helvetica 10 normal" select=1 highlite=1 edit=1 move=1 delete=1 include=1 fixed=0 source',
                                                 'physical',
                                                 'circle(4108,4065,121.16295)'
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
                                                 'reg' => 'all',
                                                 'pixels' => '46113',
                                                 'counts' => '12.000'
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
                                                     'net_counts' => '1083.000',
                                                     'reg' => '1',
                                                     'area' => '1860.26',
                                                     'background' => '2.000',
                                                     'error' => '32.944',
                                                     'surf_bri' => '0.582',
                                                     'berror' => '0.577',
                                                     'surf_err' => '0.018'
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
