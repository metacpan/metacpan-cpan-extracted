%nohup matlab -nojvm -r squareMatrix -logfile squareMatrix_matlab.out </dev/null &

clear all;
close all;

sparseSquare('/home/henryst/lbdData/squaring/1975_1999_window8_noOrder','/home/henryst/lbdData/squaring/1975_1999_window8_noOrder_squared');

error('DONE!');


function sparseSquare(fileIn, fileOut)

    %load the data
    data = load(fileIn);
    disp('   loaded data');

    %convert to sparse
    vals = max(data);
    maxVal = vals(1);
    if (vals(2) > maxVal) 
       maxVal = vals(2); 
    end
    sp = sparse(data(:,1), data(:,2), data(:,3), maxVal, maxVal);
    clear data;
    clear vals;
    clear maxVal;
    disp('   converted to sparse');

    %square the matrix
    squared = sp*sp;
    clear sp;
    disp('    squared');

    %output the matrix
    [i,j,val] = find(squared);
    clear squared;
    disp('    values grabbed for output');
    data_dump = [i,j,val];
    clear i;
    clear j;
    clear val;
    disp('    values ready for output dump');
    fid = fopen(fileOut,'w');
    fprintf( fid,'%d %d %d\n', transpose(data_dump) );
    fclose(fid);
    disp('   DONE!');

end
