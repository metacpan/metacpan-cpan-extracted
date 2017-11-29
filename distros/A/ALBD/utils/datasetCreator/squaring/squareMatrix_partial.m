%nohup matlab -nojvm -r squareMatrix_partial -logfile squareMatrix_matlab.out </dev/null &

clear all;
close all;

%The number of rows/cols to square at a time. Larger numbers will run faster
% but will require more ram. Lower numbers will run slower but require less ram.
% You want this number to be as high as possible without MATLAB crashing
increment = 40000;
sparseSquare_sectioned('/home/henryst/lbdData/squaring/1975_1999_window8_noOrder','/home/henryst/lbdData/squaring/1975_1999_window8_noOrder_squared_secondTry',increment);
error('DONE!');

function sparseSquare_sectioned(fileIn, fileOut, increment)
  disp(fileIn);

  %open, close, and clear the output file
  fid = fopen(fileOut,'w');
  fclose(fid);

  %load the data
  data = load(fileIn);
    
  vals = max(data);
  matrixSize = vals(1);
  if (vals(2) > matrixSize) 
    matrixSize = vals(2); 
  end
  disp('got matrixDim');
  clear data;

  %multiply each segment of the matrices
  for rowStartIndex = 1:increment:matrixSize
    rowEndIndex = rowStartIndex+increment-1;
    if (rowEndIndex > matrixSize) 
      rowEndIndex = matrixSize;
    end

    for colStartIndex = 1: increment: matrixSize
      colEndIndex = colStartIndex+increment-1;
      if (colEndIndex > matrixSize)
        colEndIndex = matrixSize;
      end

      dispString = [num2str(rowStartIndex), ',', num2str(rowEndIndex),' - ', num2str(colStartIndex),', ', num2str(colEndIndex),':'];
      disp(dispString)
      clear dispString;

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

      %grab a peice of the matrix
      sp1 = sparse(matrixSize,matrixSize);
      sp2 = sparse(matrixSize,matrixSize);
      sp1(rowStartIndex:rowEndIndex,:) = sp(rowStartIndex:rowEndIndex,:);
      sp2(:,colStartIndex:colEndIndex) = sp(:,colStartIndex:colEndIndex);
      clear sp;
    
      %square the matrix
      squared = sp1*sp2;
      clear sp1,sp2;
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
      fid = fopen(fileOut,'a+');
      fprintf( fid,'%d %d %d\n', transpose(data_dump) );
      clear data_dump;
      fclose(fid);
      disp('   values output');
    end
  end
end
