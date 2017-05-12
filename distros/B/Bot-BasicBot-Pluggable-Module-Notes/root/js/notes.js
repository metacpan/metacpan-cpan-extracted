jQuery(document).ready(function(){ 
  jQuery("#notesgrid").jqGrid({
    url:'/cgi-bin/notesapp.cgi/json',
    datatype: 'json',
    mtype: 'GET',
    colNames:['ID', 'Date', 'Time', 'Channel', 'Name', 'Notes'],
    colModel :[ 
      {name:'id', index:'id', width:55, align:'center'}, 
      {name:'date', index:'date', width:90}, 
      {name:'time', index:'time', width:80, align:'left'}, 
      {name:'channel', index:'channel', width:80, align:'left'}, 
      {name:'name', index:'name', width:80, align:'left'}, 
      {name:'notes', index:'notes', width:500, sortable:false} 
    ],
    pager: '#pagers',
    rowNum:10,
    rowList:[10,20,30,50,100],
    sortname: 'id',
    sortorder: 'desc',
    viewrecords: true,
    caption: 'Notes - data dump'
  }); 

jQuery("#searchbutton").click(function(){
	jQuery("#notesgrid").jqGrid('searchGrid',
		{sopt:['cn','bw','eq','ne','lt','gt','ew']}
	);
});
});

