int c_ncs(
	unsigned short int *x, 
	unsigned short int *y, 
	unsigned long int xl, 
	unsigned long int yl
	){	
    unsigned long int i;
    unsigned long int j;
    unsigned long int k;
	
	unsigned short int c[++xl][++yl];
	for(i=0; i<xl; i++)
		for(j=0; j<yl; j++)
			c[i][j] = 0;

    for(i=1; i<xl; i++)
		for(j=1; j<yl; j++){
			c[i][j] = c[i-1][j] > c[i][j-1] ? 
			c[i-1][j] : c[i][j-1]; 
			for(k=1; k<i+1  &&  k<j+1  &&  x[i-k] == y[j-k] ; k++)
				if(c[i][j] < c[i-k][j-k] + (k+1)*k/2 ) 
					c[i][j] = c[i-k][j-k] + (k+1)*k/2;}
		
    return c[xl-1][yl-1];
}