=begin comment

Copyright (c) 2025 Aspose.Cells Cloud
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=end comment

=cut

package AsposeCellsCloud::Request::PutWorksheetChartRequest;

require 5.6.0;
use strict;
use warnings;
use utf8;
use JSON ;
use Data::Dumper;
use Module::Runtime qw(use_module);
use Log::Any qw($log);
use Date::Parse;
use DateTime;
use File::Basename;

use base ("Class::Accessor", "Class::Data::Inheritable");

__PACKAGE__->mk_classdata('attribute_map' => {});
__PACKAGE__->mk_classdata('method_documentation' => {}); 
__PACKAGE__->mk_classdata('class_documentation' => {});


# new object
sub new { 
    my ($class, %args) = @_; 

	my $self = bless {}, $class;

	foreach my $attribute (keys %{$class->attribute_map}) {
		my $args_key = $class->attribute_map->{$attribute};
		$self->$attribute( $args{ $args_key } );
	}

	return $self;
}  


# Run Operation Request
# PutWorksheetChartRequest.name : The file name.  ,
# PutWorksheetChartRequest.sheetName : The worksheet name.  ,
# PutWorksheetChartRequest.chartType : Chart type, please refer property Type in chart resource.  ,
# PutWorksheetChartRequest.upperLeftRow : Upper-left row for the new chart.  ,
# PutWorksheetChartRequest.upperLeftColumn : Upper-left column for the new chart.  ,
# PutWorksheetChartRequest.lowerRightRow : Lower-left row for the new chart.  ,
# PutWorksheetChartRequest.lowerRightColumn : Lower-left column for the new chart.  ,
# PutWorksheetChartRequest.area : Specify the values from which to plot the data series.  ,
# PutWorksheetChartRequest.isVertical : Specify whether to plot the series from a range of cell values by row or by column.   ,
# PutWorksheetChartRequest.categoryData : Get or set the range of category axis values. It can be a range of cells (e.g., "D1:E10").  ,
# PutWorksheetChartRequest.isAutoGetSerialName : Specify whether to auto-update the serial name.  ,
# PutWorksheetChartRequest.title : Specify the chart title name.  ,
# PutWorksheetChartRequest.folder : The folder where the file is situated.  ,
# PutWorksheetChartRequest.dataLabels : Represents the specified chart`s data label values display behavior. True to display the values, False to hide them.  ,
# PutWorksheetChartRequest.dataLabelsPosition : Represents data label position (Center/InsideBase/InsideEnd/OutsideEnd/Above/Below/Left/Right/BestFit/Moved).  ,
# PutWorksheetChartRequest.pivotTableSheet : The source is the data of the pivotTable. If PivotSource is not empty, the chart is a PivotChart.  ,
# PutWorksheetChartRequest.pivotTableName : The pivot table name.  ,
# PutWorksheetChartRequest.storageName : The storage name where the file is situated.   

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_chart' } = { 
    	summary => 'Add a new chart in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v3.0/cells/{name}/worksheets/{sheetName}/charts';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};


    my $_header_accept = $client->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $client->select_header_content_type('application/json');
    if(defined $self->name){
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $client->to_path_value($self->name);
        $_resource_path =~ s/$_base_variable/$_base_value/g;        
    }

    if(defined $self->sheet_name){
        my $_base_variable = "{" . "sheetName" . "}";
        my $_base_value = $client->to_path_value($self->sheet_name);
        $_resource_path =~ s/$_base_variable/$_base_value/g;        
    } 
    if(defined $self->chart_type){
        $query_params->{'chartType'} = $client->to_query_value($self->chart_type);      
    }

    if(defined $self->upper_left_row){
        $query_params->{'upperLeftRow'} = $client->to_query_value($self->upper_left_row);      
    }

    if(defined $self->upper_left_column){
        $query_params->{'upperLeftColumn'} = $client->to_query_value($self->upper_left_column);      
    }

    if(defined $self->lower_right_row){
        $query_params->{'lowerRightRow'} = $client->to_query_value($self->lower_right_row);      
    }

    if(defined $self->lower_right_column){
        $query_params->{'lowerRightColumn'} = $client->to_query_value($self->lower_right_column);      
    }

    if(defined $self->area){
        $query_params->{'area'} = $client->to_query_value($self->area);      
    }

    if(defined $self->is_vertical){
        $query_params->{'isVertical'} = $client->to_query_value($self->is_vertical);      
    }

    if(defined $self->category_data){
        $query_params->{'categoryData'} = $client->to_query_value($self->category_data);      
    }

    if(defined $self->is_auto_get_serial_name){
        $query_params->{'isAutoGetSerialName'} = $client->to_query_value($self->is_auto_get_serial_name);      
    }

    if(defined $self->title){
        $query_params->{'title'} = $client->to_query_value($self->title);      
    }

    if(defined $self->folder){
        $query_params->{'folder'} = $client->to_query_value($self->folder);      
    }

    if(defined $self->data_labels){
        $query_params->{'dataLabels'} = $client->to_query_value($self->data_labels);      
    }

    if(defined $self->data_labels_position){
        $query_params->{'dataLabelsPosition'} = $client->to_query_value($self->data_labels_position);      
    }

    if(defined $self->pivot_table_sheet){
        $query_params->{'pivotTableSheet'} = $client->to_query_value($self->pivot_table_sheet);      
    }

    if(defined $self->pivot_table_name){
        $query_params->{'pivotTableName'} = $client->to_query_value($self->pivot_table_name);      
    }

    if(defined $self->storage_name){
        $query_params->{'storageName'} = $client->to_query_value($self->storage_name);      
    } 
    my $_body_data;

 

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $client->call_api($_resource_path, $_method, $query_params, $form_params, $header_params, $_body_data, $auth_settings);
    return $response;
}


__PACKAGE__->method_documentation({
     'name' => {
     	datatype => 'string',
     	base_name => 'name',
     	description => 'The file name.',
     	format => '',
     	read_only => '',
     		},
     'sheet_name' => {
     	datatype => 'string',
     	base_name => 'sheetName',
     	description => 'The worksheet name.',
     	format => '',
     	read_only => '',
     		},
     'chart_type' => {
     	datatype => 'string',
     	base_name => 'chartType',
     	description => 'Chart type, please refer property Type in chart resource.',
     	format => '',
     	read_only => '',
     		},
     'upper_left_row' => {
     	datatype => 'int',
     	base_name => 'upperLeftRow',
     	description => 'Upper-left row for the new chart.',
     	format => '',
     	read_only => '',
     		},
     'upper_left_column' => {
     	datatype => 'int',
     	base_name => 'upperLeftColumn',
     	description => 'Upper-left column for the new chart.',
     	format => '',
     	read_only => '',
     		},
     'lower_right_row' => {
     	datatype => 'int',
     	base_name => 'lowerRightRow',
     	description => 'Lower-left row for the new chart.',
     	format => '',
     	read_only => '',
     		},
     'lower_right_column' => {
     	datatype => 'int',
     	base_name => 'lowerRightColumn',
     	description => 'Lower-left column for the new chart.',
     	format => '',
     	read_only => '',
     		},
     'area' => {
     	datatype => 'string',
     	base_name => 'area',
     	description => 'Specify the values from which to plot the data series.',
     	format => '',
     	read_only => '',
     		},
     'is_vertical' => {
     	datatype => 'string',
     	base_name => 'isVertical',
     	description => 'Specify whether to plot the series from a range of cell values by row or by column. ',
     	format => '',
     	read_only => '',
     		},
     'category_data' => {
     	datatype => 'string',
     	base_name => 'categoryData',
     	description => 'Get or set the range of category axis values. It can be a range of cells (e.g., "D1:E10").',
     	format => '',
     	read_only => '',
     		},
     'is_auto_get_serial_name' => {
     	datatype => 'string',
     	base_name => 'isAutoGetSerialName',
     	description => 'Specify whether to auto-update the serial name.',
     	format => '',
     	read_only => '',
     		},
     'title' => {
     	datatype => 'string',
     	base_name => 'title',
     	description => 'Specify the chart title name.',
     	format => '',
     	read_only => '',
     		},
     'folder' => {
     	datatype => 'string',
     	base_name => 'folder',
     	description => 'The folder where the file is situated.',
     	format => '',
     	read_only => '',
     		},
     'data_labels' => {
     	datatype => 'string',
     	base_name => 'dataLabels',
     	description => 'Represents the specified chart`s data label values display behavior. True to display the values, False to hide them.',
     	format => '',
     	read_only => '',
     		},
     'data_labels_position' => {
     	datatype => 'string',
     	base_name => 'dataLabelsPosition',
     	description => 'Represents data label position (Center/InsideBase/InsideEnd/OutsideEnd/Above/Below/Left/Right/BestFit/Moved).',
     	format => '',
     	read_only => '',
     		},
     'pivot_table_sheet' => {
     	datatype => 'string',
     	base_name => 'pivotTableSheet',
     	description => 'The source is the data of the pivotTable. If PivotSource is not empty, the chart is a PivotChart.',
     	format => '',
     	read_only => '',
     		},
     'pivot_table_name' => {
     	datatype => 'string',
     	base_name => 'pivotTableName',
     	description => 'The pivot table name.',
     	format => '',
     	read_only => '',
     		},
     'storage_name' => {
     	datatype => 'string',
     	base_name => 'storageName',
     	description => 'The storage name where the file is situated.',
     	format => '',
     	read_only => '',
     		},    
});


__PACKAGE__->attribute_map( {
    'name' => 'name',
    'sheet_name' => 'sheetName',
    'chart_type' => 'chartType',
    'upper_left_row' => 'upperLeftRow',
    'upper_left_column' => 'upperLeftColumn',
    'lower_right_row' => 'lowerRightRow',
    'lower_right_column' => 'lowerRightColumn',
    'area' => 'area',
    'is_vertical' => 'isVertical',
    'category_data' => 'categoryData',
    'is_auto_get_serial_name' => 'isAutoGetSerialName',
    'title' => 'title',
    'folder' => 'folder',
    'data_labels' => 'dataLabels',
    'data_labels_position' => 'dataLabelsPosition',
    'pivot_table_sheet' => 'pivotTableSheet',
    'pivot_table_name' => 'pivotTableName',
    'storage_name' => 'storageName' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;